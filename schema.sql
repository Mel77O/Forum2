
--Dabatos
CREATE TABLE users (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    `password` VARCHAR(200) NOT NULL,
    PRIMARY KEY (id)
);

--Opleda
CREATE TABLE categories (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tags TEXT,
    PRIMARY KEY (id)
);

--nabua post
CREATE TABLE posts (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    author_id INT UNSIGNED NOT NULL,
    category_id INT UNSIGNED NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
);

CREATE TABLE replies (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    post_id INT UNSIGNED NOT NULL,
    author_id INT UNSIGNED NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
);

--Dabatos
CREATE VIEW user_view AS
SELECT id, username, email
FROM users;

CREATE VIEW post_replies_view AS
SELECT r.id AS id, r.post_id, u.username AS author_username, r.content, r.created_at
FROM replies r
JOIN users u ON r.author_id = u.id
ORDER BY r.created_at DESC;

--nabua
CREATE VIEW post_view AS
SELECT p.id AS id, u.username AS author_username, p.title, p.content, p.created_at, c.`name` AS category_name
FROM posts p
JOIN users u ON p.author_id = u.id
JOIN categories c ON p.category_id = c.id
ORDER BY p.created_at DESC;

DELIMITER //

--Dabatos
CREATE PROCEDURE create_user(
    IN p_username VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_password VARCHAR(200)
)
BEGIN
    INSERT INTO users (username, email, `password`)
    VALUES (p_username, p_email, p_password);
END //

--Opleda
CREATE PROCEDURE add_category(
    IN name_val VARCHAR(100),
    IN tags_val TEXT
)
BEGIN
    INSERT INTO categories (`name`, tags)
    VALUES (name_val, tags_val);

    SELECT LAST_INSERT_ID() as new_category_id;
END //

--nabua
CREATE PROCEDURE add_post(
    IN author_id INT,
    IN title VARCHAR(255),
    IN content TEXT,
    IN category_id_val INT
)
BEGIN
    INSERT INTO posts (author_id, title, content, category_id)
    VALUES (author_id, title, content, category_id_val);

    SELECT LAST_INSERT_ID() as new_post_id;
END //

CREATE PROCEDURE add_reply(
    IN post_id INT,
    IN author_id INT,
    IN content TEXT
)
BEGIN
    INSERT INTO replies (post_id, author_id, content)
    VALUES (post_id, author_id, content);
END //

--nabua
CREATE PROCEDURE get_post(
    IN post_id INT
)
BEGIN
    SELECT * 
    FROM post_view
    WHERE id = post_id
    LIMIT 1;
END //

CREATE PROCEDURE get_post_replies(
    IN post_id_val INT
)
BEGIN
    SELECT * 
    FROM post_replies_view
    WHERE post_id = post_id_val;
END //

--Dabatos
CREATE PROCEDURE user_login(
    IN p_username VARCHAR(100),
    IN p_password VARCHAR(200)
)
BEGIN
    SELECT id
    FROM users
    WHERE username = p_username AND `password` = p_password
    LIMIT 1;
END //

--nabua
CREATE TRIGGER post_title BEFORE INSERT
ON posts
FOR EACH ROW
BEGIN
	SET NEW.title = UPPER(NEW.title);
END //

DELIMITER ;
