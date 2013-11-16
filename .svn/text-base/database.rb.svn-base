require 'pg'

module Cruby

    class Database

        attr_accessor :connection

        def initialize
            @connection = self.class.connect
        end

        def self.connect

            if ENV['DATABASE_URL']
                dbu = URI.parse ENV['DATABASE_URL']
                db = PGconn.new :host => dbu.host,
                    :user => dbu.user,
                    :password => dbu.password,
                    :dbname => dbu.path[1..-1]
            else
                db = PGconn.new :dbname => 'cruby'
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
                 order by 
                    case when p.work_id is not null then 100 else 0 end
                   + p.billing_order desc
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
                     , concert.description
                     , concert.performed
                     , venue.name as venue_name
                     , venue.map_url as venue_map_url
                from concert
                 left join venue
                  on concert.venue_id = venue.id
                where concert.id = $1;
            EOS

            res = (@connection.exec sql, [ id ]).to_a

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


    end

end

