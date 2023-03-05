module Cruby

    class Editor < Sinatra::Base

        enable :sessions, :logging, :raise_errors
        register Sinatra::Flash

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

        get '/recents/new' do
            THE_DB.create_text_block_from_current 'RECENT', request.env['REMOTE_USER']
            redirect '/editor/recents'
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

        get '/recents' do
            @recents = (THE_DB.get_all_text_block 'RECENT')[0..2]
            erb :editor_recents, :layout => :editor_layout
        end

        get '/recent_text/:id' do
            recent_texts = THE_DB.get_text_block_by_id(params[:id])
            if recent_texts.count > 0
                @recent_text = recent_texts[0]
                erb :editor_recent_text, :layout => :editor_layout
            else
                redirect '/editor/recents'
            end
        end

        post '/recent_text/:id' do
            if params[:back]
                redirect '/editor/recents'
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
                redirect "/editor/recent_text/#{params[:id]}"
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
					elsif params[:title] !~ /\w+: \w+/
						raise "Title must be of the form Composer: Work"
					end
					THE_DB.update_work params[:id], params[:title], params[:description], request.env['REMOTE_USER']
				rescue Exception => e
					logger.error e.message
					flash[:title] = params[:title]
					flash[:description] = params[:description]
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


    end

end

