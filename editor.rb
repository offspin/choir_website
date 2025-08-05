module Choirweb

    class Editor < Sinatra::Base

        enable :sessions, :logging, :raise_errors
        register Sinatra::Flash

        use Rack::Auth::Basic, "Restricted Area" do |username, password|
            users = THE_DB.get_user(username)
            users.count > 0 ? BCrypt::Password.new(users[0]['password_hash']) == password : nil
        end

        get '/' do
            erb :editor_index, :layout => :editor_layout
        end

        get '/news' do
            @news_flashes = THE_DB.get_all_news_flash
            erb :editor_news, :layout => :editor_layout
        end

        get '/news/new' do
            THE_DB.create_news_flash
            redirect '/editor/news'
        end

        get '/homes/new' do
            THE_DB.create_text_block_from_current 'HOME', request.env['REMOTE_USER']
            redirect '/editor/homes'
        end 

        get '/news_flash/:id' do
           news_flashes = THE_DB.get_news_flash_by_id(params[:id])
           if news_flashes.count > 0
               @news_flash = news_flashes[0]
               erb :editor_news_flash, :layout => :editor_layout
           else
               redirect '/editor/news'
           end
        end

        post '/news_flash/:id' do
            if params[:back]
                redirect '/editor/news'
            else
                begin
                    THE_DB.update_news_flash params[:id], params[:from_date], params[:to_date], params[:news_flash]
                rescue Exception => e
                    logger.error e.message
                    flash[:from_date] = params[:from_date]
                    flash[:to_date] = params[:to_date]
                    flash[:news_flash] = params[:news_flash]
                    flash[:error] = e.message
                end
                redirect "/editor/news_flash/#{params[:id]}"
            end
        end

        get '/homes' do
            @homes = (THE_DB.get_all_text_block 'HOME')[0..2]
            erb :editor_homes, :layout => :editor_layout
        end

        get '/home_text/:id' do
            home_texts = THE_DB.get_text_block_by_id(params[:id])
            if home_texts.count > 0
                @home_text = home_texts[0]
                erb :editor_home_text, :layout => :editor_layout
            else
                redirect '/editor/homes'
            end
        end

        post '/home_text/:id' do
            if params[:back]
                redirect '/editor/homes'
            else
                begin
                    THE_DB.update_text_block params[:id], params[:content], request.env['REMOTE_USER']
                    if params[:is_current] == 'on'
                        THE_DB.make_text_block_current params[:id]
                    end
                rescue Exception => e 
                    logger.error e.message
                    flash[:content] = params[:content]
                    flash[:error] = e.message 
                end 
                redirect "/editor/home_text/#{params[:id]}"
            end 
        end 

		get '/works' do
			@works = THE_DB.get_all_works
			erb :editor_works, :layout => :editor_layout
		end

		get '/works/new' do
			THE_DB.create_work request.env['REMOTE_USER']
			redirect '/editor/works'
		end

		get '/work_detail/:id' do
			work_detail = THE_DB.get_work(params[:id])
			if work_detail.count > 0
				@work_detail = work_detail[0]
                @files = get_files('./public/images/content/composer') 
				erb :editor_work_detail, :layout => :editor_layout
			else
				redirect '/editor/works'
			end
		end

		post '/work_detail/:id' do
			if params[:back]
				redirect '/editor/works'
			else
				begin
					if params[:delete]
						THE_DB.delete_work params[:id]
						redirect '/editor/works'
                    elsif params[:title] !~ /^[^:]*: [^ ]+.*$/
						raise "Title must be of the form Composer: Work"
					end
					THE_DB.update_work params[:id], params[:title], 
                           params[:description], request.env['REMOTE_USER'],
                           params[:composer_image_file]
				rescue Exception => e
					logger.error e.message
					flash[:title] = params[:title]
					flash[:description] = params[:description]
                    flash[:composer_image_file] = params[:composer_image_file]
					flash[:error] = e.message
				end
				redirect "/editor/work_detail/#{params[:id]}"
			end
		end


		get '/venues/new' do
			THE_DB.create_venue request.env['REMOTE_USER']
			redirect '/editor/venues'
		end

		get '/venues' do
			@venues = THE_DB.get_all_venue
			erb :editor_venues, :layout => :editor_layout
		end

		get '/venue_detail/:id' do
			venue_detail = THE_DB.get_venue(params[:id])
			if venue_detail.count > 0
				@venue_detail = venue_detail[0]
				erb :editor_venue_detail, :layout => :editor_layout
			else
				redirect '/editor/venues'
			end
		end

		post '/venue_detail/:id' do
			if params[:back]
				redirect '/editor/venues'
			else
				begin
					if params[:delete]
						THE_DB.delete_venue params[:id]
						redirect '/editor/venues'
					elsif (params[:name]).strip == ''
						raise "Name must be provided"
					end
					THE_DB.update_venue params[:id], params[:name], params[:map_url], request.env['REMOTE_USER']
				rescue Exception => e
					logger.error e.message
					flash[:name] = params[:name]
					flash[:map_url] = params[:map_url]
					flash[:error] = e.message
				end
				redirect "/editor/venue_detail/#{params[:id]}"
			end
		end


        get '/concerts' do
            @concerts = THE_DB.get_all_concerts
            erb :editor_concerts, :layout => :editor_layout
        end

        get '/concerts/new' do
          THE_DB.create_concert request.env['REMOTE_USER']
          redirect '/editor/concerts'
        end

		get '/concert_detail/:id' do
			concert_details = THE_DB.get_concert(params[:id])
            @venues = THE_DB.get_all_venue
            @programme = THE_DB.get_programme(params[:id])
            @files = get_files('./public/images/content/poster') 
			if concert_details.count > 0
				@concert_detail = concert_details[0]
				erb :editor_concert_detail, :layout => :editor_layout
			else
				redirect '/editor/concerts'
			end
		end

		post '/concert_detail/:id' do
			if params[:back]
				redirect '/editor/concerts'
			else
				begin
					if params[:delete]
						THE_DB.delete_concert params[:id]
						redirect '/editor/concerts'
					end
                    if params[:create_programme]
                        THE_DB.create_programme params[:id], request.env['REMOTE_USER']
				        redirect "/editor/concert_detail/#{params[:id]}"
                    end    
                    performed = ''
                    if params[:performed_date]
                        performed = params[:performed_date]
                        if params[:performed_time]
                            performed += ' ' + params[:performed_time]
                        end
                    end
					THE_DB.update_concert params[:id], params[:title], 
                        params[:sub_title], params[:pricing], params[:venue], 
                        performed, params[:friendly_url], params[:description], 
                        request.env['REMOTE_USER'], params[:poster_image_file]
				rescue Exception => e
					logger.error e.message
					flash[:title] = params[:title]
                    flash[:venue] = params[:venue]
                    flash[:sub_title] = params[:sub_title]
                    flash[:performed_date] = params[:performed_date]
                    flash[:performed_time] = params[:performed_time]
                    flash[:friendly_url] = params[:friendly_url]
                    flash[:poster_image_file] = params[:poster_image_file]
					flash[:description] = params[:description]
					flash[:error] = e.message
				end
				redirect "/editor/concert_detail/#{params[:id]}"
			end
		end

        get '/programme_detail/:id/:concert_id' do
          programme_details = THE_DB.get_programme_detail params[:id]
          @works = THE_DB.get_all_works
          if programme_details.count > 0
            @programme_detail = programme_details[0]
            @programme_parts = THE_DB.get_programme_parts params[:id]
            erb :editor_programme_detail, :layout => :editor_layout
          else
            redirect "/editor/concert_detail/#{params[:concert_id]}"
          end
        end

        post '/programme_detail/:id/:concert_id' do
            if params[:back]
                redirect "/editor/concert_detail/#{params[:concert_id]}"
            else
                begin
                    if params[:delete]
                        THE_DB.delete_programme params[:id]
                        redirect "/editor/concert_detail/#{params[:concert_id]}"
                    end
                    if params[:create_programme_part]
                        THE_DB.create_programme_part params[:id], request.env['REMOTE_USER']
                        redirect "/editor/programme_detail/#{params[:id]}/#{params[:concert_id]}"
                    end
                    if ['choir', 'solo'].include?(params[:type]) && 
                        params[:description] !~ /^[^:]*: [^ ]+.*$/
						raise "Description must be of the form Composer: Work"
					end
                    THE_DB.update_programme params[:id], params[:description], 
                        params[:performance_order], params[:billing_order], 
                        params[:type], params[:work], request.env['REMOTE_USER']
				rescue Exception => e
					logger.error e.message
					flash[:description] = params[:description]
                    flash[:performance_order] = params[:performance_order]
                    flash[:billing_order] = params[:billing_order]
                    flash[:type] = params[:type]
                    flash[:work] = params[:work]
					flash[:error] = e.message
				    redirect "/editor/programme_detail/#{params[:id]}/#{params[:concert_id]}"
				end
                redirect "/editor/concert_detail/#{params[:concert_id]}"
            end

        end

        get '/programme_part_detail/:id/:programme_id/:concert_id' do
            programme_part_details = THE_DB.get_programme_part_detail params[:id]
            if programme_part_details.count > 0
                @programme_part_detail = programme_part_details[0]
                erb :editor_programme_part_detail, :layout => :editor_layout
            else
                redirect "/editor/programme_detail/#{params[:programme_id]}/#{params[:concert_id]}"
            end
        end

        post '/programme_part_detail/:id/:programme_id/:concert_id' do

            if params[:back]
                redirect "/editor/programme_detail/#{params[:programme_id]}/#{params[:concert_id]}"
            else
                begin
                    if params[:delete]
                    THE_DB.delete_programme_part params[:id]
                    redirect "/editor/programme_detail/#{params[:programme_id]}/#{params[:concert_id]}"
                end
                THE_DB.update_programme_part params[:id], params[:part_order],
                    params[:description], request.env['REMOTE_USER']
                rescue Exception => e
                    logger.error e.message
                    flash[:part_order] = params[:part_order]
                    flash[:description] = params[:description]
                    flash[:error] = e.message
                    redirect "/editor/programme_part_detail/#{params[:id]}/#{params[:programme_id]}/#{params[:concert_id]}"
                end
            end

            redirect "/editor/programme_detail/#{params[:programme_id]}/#{params[:concert_id]}"
        end

        get '/rehearsals' do
            @rehearsals = THE_DB.get_all_rehearsals
            erb :editor_rehearsals, :layout => :editor_layout
        end

        get '/rehearsal_detail/:id' do
            rehearsal_details = THE_DB.get_rehearsal(params[:id])
            @venues = THE_DB.get_all_venue
			if rehearsal_details.count > 0
				@rehearsal_detail = rehearsal_details[0]
                @rehearsal_dates = THE_DB.get_rehearsal_dates @rehearsal_detail['id']
				erb :editor_rehearsal_detail, :layout => :editor_layout
			else
				redirect '/editor/rehearsals'
			end
        end

        get '/rehearsals/new' do
          THE_DB.create_rehearsal request.env['REMOTE_USER']
          redirect '/editor/rehearsals'
        end

		post '/rehearsal_detail/:id' do
			if params[:back]
				redirect '/editor/rehearsals'
			else
				begin
					if params[:delete]
						THE_DB.delete_rehearsal params[:id]
						redirect '/editor/rehearsals'
					end
					THE_DB.update_rehearsal params[:id], params[:from_date], params[:to_date], 
                        params[:start_time], params[:venue], request.env['REMOTE_USER']
				rescue Exception => e
					logger.error e.message
                    flash[:id] = params[:id]
					flash[:from_date] = params[:from_date]
                    flash[:to_date] = params[:to_date]
                    flash[:start_time] = params[:start_time]
                    flash[:venue] = params[:venue]
					flash[:error] = e.message
				end
				redirect "/editor/rehearsal_detail/#{params[:id]}"
			end
		end

        def get_files dir
          (Dir.entries(dir).select {|f| File.file? File.join(dir, f)}).sort
        end
            

    end

end

