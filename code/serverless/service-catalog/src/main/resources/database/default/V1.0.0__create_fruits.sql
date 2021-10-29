CREATE SEQUENCE known_fruits_id_seq;
SELECT setval('known_fruits_id_seq', 3);
CREATE TABLE known_fruits
(
  id   INT,
  name VARCHAR(40)
);
INSERT INTO known_fruits(id, name) VALUES (1, 'Cherry');
INSERT INTO known_fruits(id, name) VALUES (2, 'Apple');
INSERT INTO known_fruits(id, name) VALUES (3, 'Banana');


INSERT INTO category (id, name, parent) VALUES (1, 'Fantasy', 0);
INSERT INTO category (id, name, parent) VALUES (2, 'Sci-Fi', 1);
INSERT INTO category (id, name, parent) VALUES (3, 'Mystery', 1);
INSERT INTO category (id, name, parent) VALUES (4, 'Thriller', 1);
INSERT INTO category (id, name, parent) VALUES (5, 'Romance', 0);
INSERT INTO category (id, name, parent) VALUES (6, 'Westerns', 5);
INSERT INTO category (id, name, parent) VALUES (7, 'Dystopian', 5);
INSERT INTO category (id, name, parent) VALUES (8, 'Contemporary', 5);