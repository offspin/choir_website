require 'pg'

module Cruby

    class Database

        attr_accessor :connection

        CONNECTION_OK = PG::Connection::CONNECTION_OK

        def initialize
            reconnect
        end

        def reconnect
            @connection = self.class.connect
        end


        def self.connect

            if ENV['DATABASE_URL']
                dbu = URI.parse ENV['DATABASE_URL']
                db = PG::Connection.new :host => dbu.host,
                    :user => dbu.user,
                    :password => dbu.password,
                    :dbname => dbu.path[1..-1]
            else
                db = PG::Connection.new :dbname => 'cruby'
            end

        end


        def get_last_concerts(count)

            sql = <<-EOS
                select concert.id as concert_id
                     , concert.title
                     , concert.performed
                     , venue.name as venue_name
                     , venue.map_url as venue_map_url
                from concert
                 left join venue
                  on concert.venue_id = venue.id
                where concert.performed <= current_date
                order by concert.performed desc
                limit $1;
            EOS

            res = (@connection.exec sql, [ count ]).to_a
            
        end


        def get_next_concerts(count)

            sql = <<-EOS
                select concert.id as concert_id
                     , concert.title
                     , concert.performed
                     , venue.name as venue_name
                     , venue.map_url as venue_map_url
                from concert
                 left join venue
                  on concert.venue_id = venue.id
                where concert.performed >= current_date
                order by concert.performed
                limit $1;
            EOS

            res = (@connection.exec sql, [ count ]).to_a

        end

        def get_billed_programme(concert_id)

            sql =<<-EOS
                select programme.id as programme_id
                     , billing_order
                     , description
                     , work_id
                 from programme
                where concert_id = $1
                  and billing_order > 0
                order by billing_order;
            EOS

            res = (@connection.exec sql, [ concert_id ]).to_a

        end

        def get_roles(type)

            sql = <<-EOS
                select role.name as role_name
                     , person.name as person_name
                     , role.person_id
                     , case when person.description is not null
                              then 't'::boolean else 'f'::boolean 
                       end as has_description
                from   role
                 inner join person 
                  on role.person_id = person.id
                where  type = $1
                order by priority;
            EOS

            res = (@connection.exec sql, [ type ]).to_a

        end

        def get_recent_works(count)

            sql = <<-EOS
                select p.id as programme_id
                     , p.description
                     , p.work_id
                 from  programme as p
                  inner join concert as c
                   on p.concert_id = c.id
                 where p.is_heading = 'f'::boolean
                 and p.is_interval = 'f'::boolean
                 and c.performed < current_date
                 and c.performed >= current_date - interval '1 year'
                 and p.work_id is not null
                 order by c.performed desc, coalesce(p.billing_order, 3)
                 limit $1;
            EOS

            res = (@connection.exec sql, [ count ]).to_a

        end

        def get_person(id)

            sql = <<-EOS
               select p.id 
                    , p.name 
                    , p.description
               from person as p
               where id = $1;
            EOS

            res = (@connection.exec sql, [id]).to_a

        end

        def get_person_roles(id)
            
            sql = <<-EOS
                select r.name
                     , r.type
                from   role as r
                where  r.person_id = $1
                order by r.priority
            EOS

            res = (@connection.exec sql, [id]).to_a

        end

        def get_media(source_id, source_type, count)

            sql = <<-EOS
                select m.media_type
                     , m.thumb_location
                     , m.location
                     , m.caption
                from   media as m
                where  m.source_type = $2
                and    m.source_id = $1
                order by m.display_order
                limit $3;
            EOS

            res = (@connection.exec sql, [source_id, source_type, count]).to_a

        end

        def get_images(source_id, source_type, count)

            sql = <<-EOS
                select m.thumb_location
                     , m.location
                     , m.caption
                from   media as m
                where  m.source_type = $2
                and    m.source_id = $1
                and    m.media_type = 'image'
                order by m.display_order
                limit $3;
            EOS

            res = (@connection.exec sql, [source_id, source_type, count]).to_a

        end

        def get_concert(id)

            sql = <<-EOS
                select concert.id as concert_id
                     , concert.title
                     , concert.sub_title
                     , concert.pricing
                     , concert.description
                     , concert.performed
                     , concert.friendly_url
                     , venue.name as venue_name
                     , venue.map_url as venue_map_url
                from concert
                 left join venue
                  on concert.venue_id = venue.id
                where concert.id = $1;
            EOS

            res = (@connection.exec sql, [ id ]).to_a

        end

        def get_concert_id_by_friendly_url(furl)

            sql = <<-EOS
                select concert.id from concert
                where friendly_url = $1;
            EOS

            res = (@connection.exec sql, [furl]).to_a

            return res.length == 0 ? nil : res[0]['id']

        end

        def get_programme(concert_id)

            sql = <<-EOS
                select p.id
                     , p.performance_order
                     , p.description
                     , p.work_id
                     , p.is_heading
                     , p.is_interval
                from   programme as p
                where  p.concert_id = $1
                order by p.performance_order;
            EOS

            res = (@connection.exec sql, [concert_id]).to_a

        end

        def get_programme_parts(programme_id)

            sql = <<-EOS
                select pp.part_order
                     , pp.description
                from   programme_part as pp
                where  pp.programme_id = $1
                order by pp.part_order;
            EOS

            res = (@connection.exec sql, [programme_id]).to_a

        end

        def get_concert_images(concert_id, count)

            sql = <<-EOS
                select m.thumb_location
                     , m.location
                     , m.caption
                from   media as m
                where  m.source_type = 'concert'
                and    m.source_id = $1
                and    m.media_type = 'image'
                order by m.display_order
                limit $2;
            EOS

            res = (@connection.exec sql, [concert_id, count]).to_a

        end

        def get_work(id)

            sql = <<-EOS
                select w.id
                     , w.title
                     , w.description
                from   work as w
                where  w.id = $1;
            EOS

            res = (@connection.exec sql, [id]).to_a

        end
        
        def get_system_config(name)

            sql = <<-EOS
                select sc.name
                     , sc.config_string
                     , sc.config_int
                     , sc.config_timestamp
                from   system_config as sc
                where sc.name = $1;
            EOS

            res = (@connection.exec sql, [name]).to_a
        end

        def get_news_flash

            sql = <<-EOS
                select id, news_flash, from_date, to_date
                from   news_flash
                where  current_timestamp between from_date and to_date
                order by from_date;
            EOS

            res = (@connection.exec sql).to_a
        end

        def get_all_news_flash

            sql = <<-EOS
                select id, news_flash, from_date, to_date
                from   news_flash
                where  to_date >= current_timestamp - interval '1 year'
                order by from_date desc;
            EOS

            res = (@connection.exec sql).to_a
        end

        def create_news_flash

            sql = <<-EOS
                insert into news_flash
                (from_date, to_date, news_flash)
                values
                (current_timestamp - interval '1 day',
                 current_timestamp - interval '1 day' + interval '1 minute',
                 'News flash');
            EOS

            @connection.exec sql

        end

        def get_news_flash_by_id(id)

            sql = <<-EOS
                select id, news_flash, from_date, to_date
                from   news_flash
                where  id = $1;
            EOS

            res = (@connection.exec sql, [id]).to_a
        end

        def update_news_flash(id, from_date, to_date, news_flash)
            
            sql = <<-EOS
                update news_flash
                set from_date = $2
                  , to_date = $3
                  , news_flash = $4
                where id = $1;
            EOS

            @connection.exec sql, [id, from_date, to_date, news_flash]

        end

        def get_next_rehearsals(num)

            sql = <<-EOS
                with rehearsal_series as
                ( select generate_series(from_date, to_date, '7 day'::interval) 
                       + start_time as rs_date_time,
                       venue_id
                from rehearsal )
                select rehearsal_series.rs_date_time
                     , venue.name as venue_name
                     , venue.map_url as venue_map_url
                from rehearsal_series
                 left join venue 
                  on rehearsal_series.venue_id = venue.id
                where rehearsal_series.rs_date_time > current_date
                order by rehearsal_series.rs_date_time
                limit $1;
            EOS

            res = (@connection.exec sql, [num]).to_a

        end

        def get_timetable

            sql = <<-EOS
                with rehearsal_series as
                ( select generate_series(from_date, to_date, '7 day'::interval) 
                       + start_time as rs_date_time,
                       venue_id
                from rehearsal )
                select * from 
                (
                    select rehearsal_series.rs_date_time
                         , 'Rehearsal' as item_type
                         , venue.name as venue_name
                         , venue.map_url as venue_map_url
                    from rehearsal_series
                     left join venue 
                      on rehearsal_series.venue_id = venue.id
                    where rehearsal_series.rs_date_time > current_date
                    union
                    select concert.performed
                         , 'Concert' as item_type
                         , venue.name as venue_name
                         , venue.map_url as venue_map_url
                      from concert
                       left join venue
                        on concert.venue_id = venue.id
                     where concert.performed > current_date
                 ) tt
                 order by tt.rs_date_time
            EOS

            res = (@connection.exec sql).to_a

        end

        def get_user(name)

            sql = <<-EOS
                select name
                     , full_name
                     , password_hash
                 from  user_of_system
                where  name = $1;
            EOS

            res = (@connection.exec sql, [name]).to_a

        end

        def get_all_text_block(label)

            sql = <<-EOS
                select label
                     , id
                     , updated
                     , updated_by
                     , is_current
                     , content
                 from  text_block
                where  label = $1
                order by is_current desc, updated desc;
            EOS

            res = (@connection.exec sql, [label]).to_a

        end

        def create_text_block(label, content, updated_by)

            sql = <<-EOS
                insert into text_block
                (label, content, updated_by)
                values ($1, $2, $3);
            EOS

            @connection.exec sql, [label, content, updated_by]

        end

        def create_text_block_from_current(label, updated_by)

            sql = <<-EOS
                insert into text_block
                (label, content, updated_by)
                select label
                     , content
                     , $2
                  from text_block
                 where label = $1
                   and is_current = 't'::boolean;
            EOS

            @connection.exec sql, [label, updated_by]

        end 
                

        def make_text_block_current(id)

            sql = <<-EOS
                update text_block
                   set is_current = 't'::boolean
                 where id = $1;
            EOS

            @connection.exec sql, [id]

            sql = <<-EOS
                update text_block
                   set is_current = 'f'::boolean
                 where id <> $1 
                   and label = (select label from text_block where id = $1)
                   and is_current = 't'::boolean;
            EOS

            @connection.exec sql, [id]

        end

        def update_text_block(id, content, updated_by)

            sql = <<-EOS
                update text_block
                   set content = $2
                     , updated = CURRENT_TIMESTAMP
                     , updated_by = $3
                 where id = $1;
            EOS

            @connection.exec sql, [id, content, updated_by]

        end

        def get_current_text_block (label)

            sql = <<-EOS
                select content
                  from text_block
                 where label = $1
                   and is_current = 't'::boolean;
            EOS

            res = (@connection.exec sql, [label]).to_a

        end

        def delete_text_block (id)

            sql = <<-EOS
                delete from text_block
                 where id = $1;
            EOS

            @connection.exec sql, [id]

        end

        def get_text_block_by_id (id)

            sql = <<-EOS
               select content, is_current
                 from text_block
                where id = $1;
            EOS

            res = (@connection.exec sql, [id]).to_a

        end

    end

end

