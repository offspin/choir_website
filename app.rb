module Cruby

    RECENT_WORKS_COUNT = 4
    RECENT_CONCERTS_COUNT = 3
    RECENT_REHEARSALS_COUNT = 1


    class App < Sinatra::Base

        enable :sessions, :logging, :raise_errors
        register Sinatra::Flash

        Recaptcha.configure do |conf|
            conf.site_key = ENV['RECAPTCHA_SITE_KEY']
            conf.secret_key = ENV['RECAPTCHA_SECRET_KEY']
        end 

        include Recaptcha::ClientHelper
        include Recaptcha::Verify

        before do

            if request.host =~ /herokudns.com/
                redirect 'https://www.letchworth-chorale.org.uk', 301
            end
           
            if ENV['RACK_ENV'] != 'development'  
                redirect request.url.sub('http://', 'https://') unless request.secure?
            end

            user_agent = request.env['HTTP_USER_AGENT']

            @is_mobile = (user_agent =~ /mobile/i) || (user_agent =~ /android/i)
            @is_ipad = (user_agent =~ /ipad/i)
            @use_recaptcha = (ENV['RECAPTCHA_SITE_KEY'] != nil)
            

            if THE_DB.connection.status != Database::CONNECTION_OK
                THE_DB.reconnect
            end

            get_music_roles
            get_recent_works
            get_next_concerts
            get_next_rehearsals
            
            response.headers['Cache-Control'] = 'no-cache'


        end

        get '/' do
            @news_flash = get_news_flash
            @home_text = get_current_text_block 'HOME'
            erb :index
        end

        get '/people/:id' do

            get_person(params[:id])

            if @person
                erb :people 
            else
                redirect url('/')
            end

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
                from(email_address)
                to(recipients)
                subject('[Letchworth Chorale]:' + subject)
                body("Message from #{name} via #{this_url}\n\n" + message)
                delivery_method :smtp, {
                    :address => 'smtp.sendgrid.net',
                    :port => 587,
                    :domain => 'heroku.com',
                    :user_name => ENV['SENDGRID_USERNAME'],
                    :password => ENV['SENDGRID_PASSWORD'],
                    :authentication => :plain,
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

        def get_music_roles

            @music_roles = THE_DB.get_roles 'Music'

            @music_roles.each do |mr|
                
                mr['htm_person_name'] = mr['person_name']

                if mr['has_description'] == 't'
                    mr['htm_person_name'] = 
                        "<a href=\"/people/#{mr['person_id']}\">#{mr['htm_person_name']}</a>"
                end

            end

        end

        def get_recent_works

            @recent_works = THE_DB.get_recent_works RECENT_WORKS_COUNT

            @recent_works.each do |w|
                w['htm_description'] = w['description'].gsub(/^(.*:)(.*)$/, '\1<em>\2</em>')

                if w['work_id']
                    w['htm_description'] = 
                        "<a href=\"/works/#{w['work_id']}\">#{w['htm_description']}</a>"
                end

            end

        end
       
        def get_next_concerts

            @next_concerts = THE_DB.get_next_concerts RECENT_CONCERTS_COUNT

            @next_concerts.each do |c|

                c['long_date'] = DateTime.parse(c['performed']).strftime('%A %d %B %Y')
                c['htm_long_date'] = c['long_date']
                c['htm_venue_name'] = c['venue_name']

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
                end

                if c['venue_map_url']
                    c['htm_venue_name'] = 
                        "<a href=\"#{c['venue_map_url']}\" target=\"_blank\">#{c['venue_name']}</a>"
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

                images = THE_DB.get_images id, 'concert', @is_mobile ? 2 : 3
                @concert['images'] = images


            end

        end

        def get_concert_by_friendly_url(furl)

            concert_id = THE_DB.get_concert_id_by_friendly_url(furl)

            get_concert concert_id

        end

        def get_person(id)

            people = THE_DB.get_person id

            if people.count > 0
                @person = people[0]

                images = THE_DB.get_images id, 'person', @is_mobile ? 2 : 3
                @person['images'] = images

                roles = THE_DB.get_person_roles id
                @person['roles'] = roles
            end

        end

        def get_work(id)

            works = THE_DB.get_work id

            if works.count > 0
                @work = works[0]

                media = THE_DB.get_media id, 'work', @is_mobile ? 2 : 3
                @work['media'] = media

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

            @next_rehearsals = THE_DB.get_next_rehearsals RECENT_REHEARSALS_COUNT

            @next_rehearsals.each do |r|
                r['long_date'] = DateTime.parse(r['rs_date_time']).strftime('%A %d %B %Y')
                r['htm_venue_name'] = r['venue_name']

                if r['venue_map_url']
                    r['htm_venue_name'] = 
                        "<a href=\"#{r['venue_map_url']}\" target=\"_blank\">#{r['venue_name']}</a>"
                end

            end
        end

        def get_current_text_block (label)
            rows = THE_DB.get_current_text_block label
            content = rows.length == 0 ? '' : rows[0]['content']
        end

        
    end

end

