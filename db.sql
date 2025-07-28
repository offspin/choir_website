--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Ubuntu 17.5-1.pgdg24.04+1)
-- Dumped by pg_dump version 17.5 (Ubuntu 17.5-1.pgdg24.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: concert_sequence; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.concert_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: concert; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.concert (
    id integer DEFAULT nextval('public.concert_sequence'::regclass) NOT NULL,
    title character varying(50) NOT NULL,
    sub_title character varying(50),
    pricing character varying(200),
    description text,
    performed timestamp without time zone,
    venue_id integer,
    friendly_url character varying(200),
    updated timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) NOT NULL
);


--
-- Name: media; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media (
    id integer NOT NULL,
    source_id character varying(11) NOT NULL,
    source_type character varying(20) NOT NULL,
    media_type character varying(20) NOT NULL,
    display_order integer NOT NULL,
    caption character varying(100),
    location character varying(1000) NOT NULL,
    thumb_location character varying(1000)
);


--
-- Name: news_flash_sequence; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.news_flash_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: news_flash; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.news_flash (
    from_date timestamp without time zone NOT NULL,
    to_date timestamp without time zone NOT NULL,
    news_flash text NOT NULL,
    id integer DEFAULT nextval('public.news_flash_sequence'::regclass) NOT NULL
);


--
-- Name: person; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.person (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text
);


--
-- Name: programme; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programme (
    id integer NOT NULL,
    concert_id integer NOT NULL,
    billing_order integer NOT NULL,
    performance_order integer NOT NULL,
    description character varying(100),
    work_id integer,
    is_heading boolean NOT NULL,
    is_interval boolean NOT NULL,
    is_solo boolean
);


--
-- Name: programme_part; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programme_part (
    programme_id integer NOT NULL,
    part_order integer NOT NULL,
    description character varying(100) NOT NULL
);


--
-- Name: rehearsal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rehearsal (
    from_date date NOT NULL,
    to_date date NOT NULL,
    start_time time without time zone NOT NULL,
    venue_id integer
);


--
-- Name: role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role (
    name character varying(50) NOT NULL,
    type character varying(50) NOT NULL,
    priority integer NOT NULL,
    person_id integer
);


--
-- Name: system_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_config (
    name character varying(50) NOT NULL,
    config_string character varying(1000),
    config_int integer,
    config_timestamp timestamp without time zone
);


--
-- Name: text_block_sequence; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.text_block_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: text_block; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.text_block (
    label character varying(20) NOT NULL,
    id integer DEFAULT nextval('public.text_block_sequence'::regclass) NOT NULL,
    updated timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) NOT NULL,
    is_current boolean DEFAULT false,
    content text NOT NULL
);


--
-- Name: text_block_label; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.text_block_label (
    label character varying(20) NOT NULL,
    description character varying(200) NOT NULL
);


--
-- Name: user_of_system; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_of_system (
    name character varying(20) NOT NULL,
    full_name character varying(50) NOT NULL,
    password_hash character varying(500) NOT NULL
);


--
-- Name: venue_sequence; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.venue_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: venue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.venue (
    id integer DEFAULT nextval('public.venue_sequence'::regclass) NOT NULL,
    name character varying(50) NOT NULL,
    map_url character varying(500),
    updated timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) NOT NULL
);


--
-- Name: work_sequence; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.work_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.work (
    id integer DEFAULT nextval('public.work_sequence'::regclass) NOT NULL,
    title character varying(100) NOT NULL,
    description text,
    updated timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) NOT NULL
);


--
-- Name: news_flash ak_news_flash; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_flash
    ADD CONSTRAINT ak_news_flash UNIQUE (from_date, to_date);


--
-- Name: person ak_person; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT ak_person UNIQUE (name);


--
-- Name: programme ak_programme; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme
    ADD CONSTRAINT ak_programme UNIQUE (concert_id, performance_order);


--
-- Name: concert pk_concert; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.concert
    ADD CONSTRAINT pk_concert PRIMARY KEY (id);


--
-- Name: media pk_media; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT pk_media PRIMARY KEY (id);


--
-- Name: news_flash pk_news_flash; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_flash
    ADD CONSTRAINT pk_news_flash PRIMARY KEY (id);


--
-- Name: person pk_person; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT pk_person PRIMARY KEY (id);


--
-- Name: programme pk_programme; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme
    ADD CONSTRAINT pk_programme PRIMARY KEY (id);


--
-- Name: programme_part pk_programme_part; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_part
    ADD CONSTRAINT pk_programme_part PRIMARY KEY (programme_id, part_order);


--
-- Name: rehearsal pk_rehearsal; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rehearsal
    ADD CONSTRAINT pk_rehearsal PRIMARY KEY (from_date);


--
-- Name: role pk_role; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT pk_role PRIMARY KEY (name);


--
-- Name: system_config pk_system_config; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_config
    ADD CONSTRAINT pk_system_config PRIMARY KEY (name);


--
-- Name: text_block pk_text_block; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.text_block
    ADD CONSTRAINT pk_text_block PRIMARY KEY (id);


--
-- Name: text_block_label pk_text_block_label; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.text_block_label
    ADD CONSTRAINT pk_text_block_label PRIMARY KEY (label);


--
-- Name: user_of_system pk_user_of_system; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_of_system
    ADD CONSTRAINT pk_user_of_system PRIMARY KEY (name);


--
-- Name: venue pk_venue; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venue
    ADD CONSTRAINT pk_venue PRIMARY KEY (id);


--
-- Name: work pk_work; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work
    ADD CONSTRAINT pk_work PRIMARY KEY (id);


--
-- Name: concert fk_concert_user_of_system; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.concert
    ADD CONSTRAINT fk_concert_user_of_system FOREIGN KEY (updated_by) REFERENCES public.user_of_system(name);


--
-- Name: concert fk_concert_venue; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.concert
    ADD CONSTRAINT fk_concert_venue FOREIGN KEY (venue_id) REFERENCES public.venue(id);


--
-- Name: programme fk_programme_concert; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme
    ADD CONSTRAINT fk_programme_concert FOREIGN KEY (concert_id) REFERENCES public.concert(id);


--
-- Name: programme_part fk_programme_part_programme; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_part
    ADD CONSTRAINT fk_programme_part_programme FOREIGN KEY (programme_id) REFERENCES public.programme(id);


--
-- Name: programme fk_programme_work; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme
    ADD CONSTRAINT fk_programme_work FOREIGN KEY (work_id) REFERENCES public.work(id);


--
-- Name: rehearsal fk_rehearsal_venue; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rehearsal
    ADD CONSTRAINT fk_rehearsal_venue FOREIGN KEY (venue_id) REFERENCES public.venue(id);


--
-- Name: role fk_role_person; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT fk_role_person FOREIGN KEY (person_id) REFERENCES public.person(id);


--
-- Name: text_block fk_text_block_label; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.text_block
    ADD CONSTRAINT fk_text_block_label FOREIGN KEY (label) REFERENCES public.text_block_label(label);


--
-- Name: text_block fk_text_block_user_of_system; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.text_block
    ADD CONSTRAINT fk_text_block_user_of_system FOREIGN KEY (updated_by) REFERENCES public.user_of_system(name);


--
-- Name: work fk_work_user_of_system; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work
    ADD CONSTRAINT fk_work_user_of_system FOREIGN KEY (updated_by) REFERENCES public.user_of_system(name);


--
-- Name: TABLE concert; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.concert TO choirweb;


--
-- Name: TABLE media; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.media TO choirweb;


--
-- Name: TABLE news_flash; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.news_flash TO choirweb;


--
-- Name: TABLE person; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.person TO choirweb;


--
-- Name: TABLE pg_stat_statements; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.pg_stat_statements TO choirweb;


--
-- Name: TABLE pg_stat_statements_info; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.pg_stat_statements_info TO choirweb;


--
-- Name: TABLE programme; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.programme TO choirweb;


--
-- Name: TABLE programme_part; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.programme_part TO choirweb;


--
-- Name: TABLE rehearsal; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.rehearsal TO choirweb;


--
-- Name: TABLE role; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.role TO choirweb;


--
-- Name: TABLE system_config; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.system_config TO choirweb;


--
-- Name: TABLE text_block; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.text_block TO choirweb;


--
-- Name: TABLE text_block_label; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.text_block_label TO choirweb;


--
-- Name: TABLE user_of_system; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.user_of_system TO choirweb;


--
-- Name: TABLE venue; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.venue TO choirweb;


--
-- Name: TABLE work; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.work TO choirweb;


--
-- PostgreSQL database dump complete
--

