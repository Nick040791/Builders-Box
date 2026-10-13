-- Optional extra seed data for JMeter runs (run AFTER database/create-database.sql).
-- Adds 30 public builds so paging (page 0-1, size 12) and the search sampler have real rows.
-- Remove later with: DELETE FROM builds WHERE name LIKE 'LoadTest %';
USE flexpath_final;

INSERT INTO builds (name, description, is_public, username) VALUES
('LoadTest Workstation Build 01', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Streaming Build 02', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user'),
('LoadTest Budget Build 03', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Compact Build 04', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user'),
('LoadTest Silent Build 05', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Creator Build 06', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user'),
('LoadTest Office Build 07', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Home Lab Build 08', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user'),
('LoadTest Esports Build 09', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Gaming Build 10', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user'),
('LoadTest Workstation Build 11', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Streaming Build 12', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user'),
('LoadTest Budget Build 13', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Compact Build 14', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user'),
('LoadTest Silent Build 15', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Creator Build 16', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user'),
('LoadTest Office Build 17', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Home Lab Build 18', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user'),
('LoadTest Esports Build 19', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Gaming Build 20', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user'),
('LoadTest Workstation Build 21', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Streaming Build 22', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user'),
('LoadTest Budget Build 23', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Compact Build 24', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user'),
('LoadTest Silent Build 25', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Creator Build 26', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user'),
('LoadTest Office Build 27', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Home Lab Build 28', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user'),
('LoadTest Esports Build 29', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'guest_builder'),
('LoadTest Gaming Build 30', 'Seeded for JMeter load testing. Safe to delete.', TRUE, 'user');

-- Give every seeded build 2-4 public parts so hasParts=true and /builds/{id}/parts return data.
INSERT INTO build_parts (build_id, part_id, quantity)
SELECT b.id, p.id, 1
FROM builds b
JOIN parts p ON p.is_public = TRUE AND MOD(p.id + b.id, 5) = 0
WHERE b.name LIKE 'LoadTest %';
