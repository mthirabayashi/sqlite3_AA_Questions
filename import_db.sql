DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

DROP TABLE if exists questions;

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)

);

DROP TABLE if exists question_follows;

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  questions_id INTEGER NOT NULL,
  users_id INTEGER NOT NULL
);

DROP TABLE if exists replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  questions_id INTEGER NOT NULL,
  parent_id INTEGER,
  users_id INTEGER NOT NULL,
  body TEXT NOT NULL,


  FOREIGN KEY (questions_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (users_id) REFERENCES users(id)

);

DROP TABLE if exists question_likes;

  CREATE TABLE question_likes (
    id INTEGER PRIMARY KEY,
    questions_id INTEGER NOT NULL,
    users_id INTEGER NOT NULL,
    FOREIGN KEY (questions_id) REFERENCES questions(id),
    FOREIGN KEY (users_id) REFERENCES users(id)

);


INSERT INTO
  users (id, fname, lname)
VALUES
  (1, 'big', 'cow'),
  (2, 'William', 'Shakespeare'),
  (3, 'John', 'Snow'),
  (4, 'Bob', 'H'),
  (5, 'Joe', 'J');

INSERT INTO
  questions (id, title, body, author_id)
VALUES
  (1, 'Milk?', 'Got milk?', 1),
  (2, 'to be or not', 'To be or not to be', 2),
  (3, 'Chocolate?', 'Got chocolate milk?', 1);

INSERT INTO
  question_follows (id, questions_id, users_id)
VALUES
  (1, 1, 1),
  (2, 2, 2),
  (3, 2, 4),
  (4, 2, 5),
  (5, 1, 5),
  (6, 3, 4);

INSERT INTO
  replies (id, questions_id, parent_id, users_id, body)
VALUES
  (1, 1, NULL, 1, 'No, but I have cereal' ),
  (2, 2, NULL, 2, 'fake it till you make it'),
  (3, 1, 1, 2, 'Cool, I like cereal'),
  (4, 1, 1, 3, 'I''m John Snow and I like cereal too');

INSERT INTO
  question_likes (id, questions_id, users_id)
VALUES
  (1, 1, 3),
  (2, 2, 3),
  (3, 2, 4),
  (4, 2, 5),
  (5, 1, 1),
  (6, 1, 4);
