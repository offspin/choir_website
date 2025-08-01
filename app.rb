module Choirweb

    RECENT_WORKS_COUNT = 10
    MAX_RECENT_PER_CONCERT = 5
    PAST_CONCERTS_COUNT_FULL = 15
    PAST_CONCERTS_COUNT_SHORT = 4
    NEXT_CONCERTS_COUNT = 10
    NEXT_REHEARSALS_COUNT = 1


    class App < Sinatra::Base

        enable :sessions, :logging, :raise_errors
        register Sinatra::Flash

        Recaptcha.configure do |conf|
            conf.site_key = ENV['RECAPTCHA_SITE_KEY']
            conf.secret_key = ENV['RECAPTCHA_SECRET_KEY']
        end 

        include Recaptcha::Adapters::ViewMethods
        include Recaptcha::Adapters::ControllerMethods

        before do

            user_agent = request.env['HTTP_USER_AGENT']

            @is_mobile = (user_agent =~ /mobile/i) || (user_agent =~ /android/i)
            @is_ipad = (user_agent =~ /ipad/i)
            @use_recaptcha = (ENV['RECAPTCHA_SITE_KEY'] != nil)
            

            if THE_DB.connection.status != Database::CONNECTION_OK
                THE_DB.reconnect
            end

            get_recent_works
            get_next_concerts
            get_past_concerts 
            get_next_rehearsals
            get_timetable
            
            response.headers['Cache-Control'] = 'no-cache'


        end

        get '/' do
            @news_flash = get_news_flash
            @home_text = get_current_text_block 'HOME'
            erb :index
        end

        get %r{/concerts/([0-9]+)} do |id|

            get_concert(id)

            if @concert

                if @concert['friendly_url']
                    redirect url("/concerts/#{@concert['friendly_url']}")
                end

                erb :concerts
            else
                redirect url('/')
            end

        end

        get %r{/concerts/([a-z]+[a-z0-9\-]*)} do |furl|

            get_concert_by_friendly_url(furl)

            if @concert
                erb :concerts
            else
                redirect url('/')
            end

        end

        get '/works/:id' do

            get_work(params[:id])

            if @work
                erb :works
            else
                redirect url('/')
            end

        end
        
        get '/contact' do
            erb :contact
        end

        post '/contact' do


            name = (params[:name]).strip
            email_address = (params[:email_address]).strip
            subject = (params[:subject]).strip
            message = (params[:message]).strip
            this_url = request.url
            recipients = get_system_config_string('contact_email_recipients') || 'admin@offspin.com'

            error_message = ''

            if name == '' || email_address == '' || subject == '' || message == ''
                error_message = 'Please fill in all the details'
            elsif email_address !~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/  
                error_message = 'Email address is not valid'
            elsif @use_recaptcha && (!verify_recaptcha)
                error_message = 'Verification not valid'
            end

            if error_message != ''
                flash[:error] = error_message
                flash[:name] = name
                flash[:email_address] = email_address
                flash[:subject] = subject
                flash[:message] = message
                redirect url('/contact')
            end

            mail = Mail.new do
                from        ENV['EMAIL_SENDER_ACCOUNT']
                to          recipients
                subject     '[Letchworth Chorale]:' + subject
                body        "Message from #{name} (#{email_address}) via #{this_url}\n\n" + message
                delivery_method :smtp, {
                    :address =>              ENV['EMAIL_SMTP_SERVER'],
                    :user_name  =>           ENV['EMAIL_SENDER_ACCOUNT'],
                    :password =>             ENV['EMAIL_SENDER_PASSWORD'],
                    :port =>                 587,
                    :domain =>               'letchworth-chorale.org.uk',
                    :authentication =>       'plain',
                    :enable_starttls_auto => true
                }
            end

            begin
              mail.deliver
              redirect url('/thanks_for_contact')
            rescue Exception => e
              logger.error e.message
              flash[:error] = e.message
              flash[:name] = name
              flash[:email_address] = email_address
              flash[:subject] = subject
              flash[:message] = message
              redirect url('/contact')
            end

        end

        get '/thanks_for_contact' do
            erb :thanks_for_contact
        end

        get '/timetable' do
            erb :timetable
        end

        get '/past_concerts' do
            get_past_concerts 
            erb :past_concerts
        end

        def get_recent_works

            @recent_works = THE_DB.get_recent_works RECENT_WORKS_COUNT, MAX_RECENT_PER_CONCERT

            @recent_works.each do |w|
                w['htm_description'] = w['description'].gsub(/^(.*:)(.*)$/, '\1<em>\2</em>')

                if w['work_id']
                    w['htm_description'] = 
                        "<a href=\"/works/#{w['work_id']}\">#{w['htm_description']}</a>"
                end

            end

        end
       
        def get_next_concerts

            @next_concerts = THE_DB.get_next_concerts NEXT_CONCERTS_COUNT

            @next_concerts.each do |c|

                c['long_date'] = DateTime.parse(c['performed']).strftime('%A %d %B %Y')
                c['htm_long_date'] = c['long_date']
                c['htm_venue_name'] = c['venue_name']
                c['htm_title'] = c['title']

                billed_prog = THE_DB.get_billed_programme c['concert_id']

                billed_prog.each do |bp|

                    bp['htm_description'] = bp['description'].gsub(/^(.*:)(.*)$/, '\1<em>\2</em>')

                    if bp['work_id']
                        bp['htm_description'] = 
                            "<a href=\"/works/#{bp['work_id']}\">#{bp['htm_description']}</a>"
                    end
                           
                end

                c['billed_programme'] = billed_prog

                if billed_prog.count > 0
                    c['htm_long_date'] =
                        "<a href=\"/concerts/#{c['concert_id']}\">#{c['long_date']}</a>"
                    c['htm_title'] =
                        "<a href=\"/concerts/#{c['concert_id']}\">#{c['title']}</a>"
                end

                if c['venue_map_url']
                    c['htm_venue_name'] = 
                        "<a href=\"#{c['venue_map_url']}\" target=\"_blank\">#{c['venue_name']}</a>"
                end
                        

            end


        end

        def get_past_concerts

            @past_concerts = THE_DB.get_past_concerts PAST_CONCERTS_COUNT_FULL
            @past_concerts_count_short = PAST_CONCERTS_COUNT_SHORT

            @past_concerts.each do |c|

                c['long_date'] = DateTime.parse(c['performed']).strftime('%A %d %B %Y')
                c['htm_title'] = c['title']

                if c['has_programme'] == 't'
                    c['htm_title'] = "<a href=\"/concerts/#{c['friendly_url']}\">#{c['title']}</a>"
                end

            end


        end

        def get_concert(id)

            concerts = THE_DB.get_concert id


            if concerts.count > 0

                @concert = concerts[0]

                @concert_performed = DateTime.parse(@concert['performed'])

                @concert['long_date'] = @concert_performed.strftime('%A, %d %B %Y')

                if @concert_performed.hour > 0 
                    @concert['long_date'] += @concert_performed.strftime(' at %l:%M %P')
                end

                @concert['htm_venue_name'] = @concert['venue_name']

                if @concert['venue_map_url']
                    @concert['htm_venue_name'] = 
                        "<a href=\"#{@concert['venue_map_url']}\" target=\"_blank\">#{@concert['venue_name']}</a>"
                end

                programme = THE_DB.get_programme id

                programme.each do |pr|
                    pr['htm_description'] = pr['description'].gsub(/^(.*:)(.*)$/, '\1<em>\2</em>')

                    if pr['work_id']
                        pr['htm_description'] = 
                            "<a href=\"/works/#{pr['work_id']}\">#{pr['htm_description']}</a>"
                    end

                    parts = THE_DB.get_programme_parts pr['id']
                    pr['parts'] = parts


                end
                @concert['programme'] = programme


            end

        end

        def get_concert_by_friendly_url(furl)

            concert_id = THE_DB.get_concert_id_by_friendly_url(furl)

            get_concert concert_id

        end

        def get_work(id)

            works = THE_DB.get_work id

            if works.count > 0
                @work = works[0]
            end

        end

        def get_system_config_string(name)
            
            configs = THE_DB.get_system_config(name)

            if configs.count == 0
                return nil
            else
                return (configs[0]['config_string'])
            end

        end

        def get_news_flash

            flashes = THE_DB.get_news_flash

            if flashes.count == 0
                return nil
            else
                return (flashes[0]['news_flash'])
            end

        end

        def get_next_rehearsals

            @next_rehearsals = THE_DB.get_next_rehearsals NEXT_REHEARSALS_COUNT

            @next_rehearsals.each do |r|
                r['long_date'] = DateTime.parse(r['rs_date_time']).strftime('%A %d %B %Y')
                r['htm_venue_name'] = r['venue_name']

                if r['venue_map_url']
                    r['htm_venue_name'] = 
                        "<a href=\"#{r['venue_map_url']}\" target=\"_blank\">#{r['venue_name']}</a>"
                end

            end
        end

        def get_timetable

            @timetable = THE_DB.get_timetable

            @timetable.each do |r|
                r['long_date'] = DateTime.parse(r['rs_date_time']).strftime('%A %d %B %Y')
                r['htm_venue_name'] = r['venue_name']
                r['htm_item_type'] = r['item_type']

                if r['venue_map_url']
                    r['htm_venue_name'] = 
                        "<a href=\"#{r['venue_map_url']}\" target=\"_blank\">#{r['venue_name']}</a>"
                end

                if r['item_type'] == 'Concert'&& r['has_programme'] == 't'
                    r['htm_item_type'] = 
                      "<a href=\"/concerts/#{r['concert_id']}\">#{r['item_type']}</a>"
                end

            end
        end

        def get_current_text_block (label)
            rows = THE_DB.get_current_text_block label
            content = rows.length == 0 ? '' : rows[0]['content']
        end

        
    end

end

