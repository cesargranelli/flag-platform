-- V2__create_spring_modulith_event_publication.sql
-- Spring Modulith - Event Publication Registry
-- Required by spring-modulith-starter-jpa
-- Must be in the same schema as hibernate.default_schema (platform)

CREATE TABLE IF NOT EXISTS platform.event_publication (
    id               UUID                     NOT NULL,
    listener_id      TEXT                     NOT NULL,
    event_type       TEXT                     NOT NULL,
    serialized_event TEXT                     NOT NULL,
    publication_date TIMESTAMP WITH TIME ZONE NOT NULL,
    completion_date  TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS idx_event_publication_completion_date
    ON platform.event_publication (completion_date);
