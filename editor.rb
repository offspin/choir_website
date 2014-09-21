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

    end

end

