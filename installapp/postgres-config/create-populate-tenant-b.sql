CREATE SEQUENCE product_id_seq START 1;

CREATE TABLE product
(
  id SERIAL PRIMARY KEY,
  price DECIMAL(14,2) NOT NULL,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  image TEXT NOT NULL
);

INSERT INTO product VALUES (nextval('product_id_seq'), 19.99, 'Beautiful Disaster', 'The new Abby Abernathy is a good girl.', 'images/beautifuldisaster.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 9.99, 'Dune', 'Dune is a 1965 science fiction novel by American author Frank Herbert', 'images/dune.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 15.99, 'Jade City', 'The Kaul family is one of two crime syndicates that control the island of Kekon.', 'images/greenbone.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 12.00, 'The Heart Principle', 'When violinist Anna Sun accidentally achieves career success with a viral YouTube video', 'images/heartprinciple.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 20.00, 'Handmaids Tale', 'It is set in a near-future New England, in a strongly patriarchal, totalitarian theonomic state, known as Republic of Gilead.', 'images/handmaidstale.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 30.00, 'Ancillary Justice', ' It is Leckies debut novel and the first in her Imperial Radch space opera trilogy', 'images/imperial.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 18.00, 'A Lesson in Vengence', 'Perched in the Catskill mountains, the centuries-old, ivy-covered campus was home until the tragic death of her girlfriend.', 'images/lessonvengence.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 11.00, 'The Lord of the Rings', 'The Lord of the Rings is a series of three epic fantasy adventure films directed by Peter Jackson, based on the novel written by J. R. R. Tolkien', 'images/lordofrings.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 22.00, 'A Slow Fire Burning', 'When a young man is found gruesomely murdered in a London houseboat, it triggers questions about three women who knew him.', 'images/slowfire.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 27.00, 'The Guide', 'Kingfisher Lodge, nestled in a canyon on a mile and a half of the most pristine river water on the planet', 'images/theguide.jpg');


CREATE SEQUENCE category_id_seq START 1;
CREATE TABLE category
(
  id   SERIAL PRIMARY KEY ,
  name TEXT NOT NULL,
  parent INT
);

INSERT INTO category VALUES (nextval('category_id_seq'), 'Fantasy', null);
INSERT INTO category VALUES (nextval('category_id_seq'), 'Thriller', 1);
INSERT INTO category VALUES (nextval('category_id_seq'), 'Mystery', 1);
INSERT INTO category VALUES (nextval('category_id_seq'), 'Fiction', 1);
INSERT INTO category VALUES (nextval('category_id_seq'), 'Non-Fiction', null);

CREATE SEQUENCE productcategory_id_seq START 1;
CREATE TABLE productcategory
(
  id   SERIAL PRIMARY KEY ,
  productid INT,
  categoryid INT
);

INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 1, 2); 
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 2, 2); 
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 3, 2); 
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 4, 5);
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 5, 5);
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 6, 3);
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 7, 4);
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 8, 4);
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 9, 2);
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 10, 1);


