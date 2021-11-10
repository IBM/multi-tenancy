CREATE SEQUENCE product_id_seq START 1;

CREATE TABLE product
(
  id SERIAL PRIMARY KEY,
  price DECIMAL(14,2) NOT NULL,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  image TEXT NOT NULL
);

INSERT INTO product VALUES (nextval('product_id_seq'), 29.99, 'Return of the Jedi', 'Episode 6, Luke has the final confrontation with his father!', 'images/Return.jpg');  
INSERT INTO product VALUES (nextval('product_id_seq'), 39.99, 'Empire Strikes Back', 'Episode 5, Luke finds out a secret that will change his destiny', 'images/Empire.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 49.99, 'New Hope', 'Episode 4, after years of oppression, a band of rebels fight for freedom', 'images/NewHope.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 100.00, 'DVD Player', 'This Sony Player has crystal clear picture', 'images/Player.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 200.00, 'BlackBerry Curve', 'This BlackBerry offers rich PDA functions and works with Notes.', 'images/BlackBerry.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 150.00, 'Sony Ericsson', 'This Sony phone takes pictures and plays Music.', 'images/SonyPhone.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 1800.00, 'Sony Bravia', 'This is a 40 inch 1080p LCD HDTV', 'images/SonyTV.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 1150.00, 'Sharp Aquos', 'This is 32 inch 1080p LCD HDTV', 'images/SamTV.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 20.00, 'Go Fish: Superstar', 'Go Fish release their great new hit, Superstar', 'images/Superstar.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 20.00, 'Ludwig van Beethoven', 'This is a classic, the 9 Symphonies Box Set', 'images/Bet.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 399.99, 'PlayStation 3', 'Brace yourself for the marvels of the PlayStation 3 complete with 80GB hard disk storage', 'images/PS3.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 169.99, 'Nintendo Wii', 'Next-generation gaming with a motion-sensitive controller', 'images/wii.jpg');
INSERT INTO product VALUES (nextval('product_id_seq'), 299.99, 'XBOX 360', 'Expand your horizons with the gaming and multimedia capabilities of this incredible system', 'images/xbox360.jpg');    


CREATE SEQUENCE category_id_seq START 1;
CREATE TABLE category
(
  id   SERIAL PRIMARY KEY ,
  name TEXT NOT NULL,
  parent INT
);

INSERT INTO category VALUES (nextval('category_id_seq'), 'Entertainment', null); 
INSERT INTO category VALUES (nextval('category_id_seq'), 'Movies', 1); 
INSERT INTO category VALUES (nextval('category_id_seq'), 'Music', 1); 
INSERT INTO category VALUES (nextval('category_id_seq'), 'Games', 1); 
INSERT INTO category VALUES (nextval('category_id_seq'), 'Electronics', null); 
INSERT INTO category VALUES (nextval('category_id_seq'), 'TV', 5); 
INSERT INTO category VALUES (nextval('category_id_seq'), 'CellPhones', 5); 
INSERT INTO category VALUES (nextval('category_id_seq'), 'DVD Players', 5); 

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
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 4, 8); 
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 5, 7); 
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 6, 7); 
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 7, 6); 
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 8, 6); 
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 9, 4); 
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 10, 3); 
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 11, 4); 
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 12, 4); 
INSERT INTO productcategory VALUES (nextval('productcategory_id_seq'), 13, 4); 

