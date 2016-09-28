require 'sqlite3'
require 'singleton'

class QuestionsDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User

  def self.find_by_id(id)
    user = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil unless user.length > 0
    # p user.first
    User.new(user.first) # play is stored in an array!
  end

  def self.find_by_name(fname, lname)
    user = QuestionsDBConnection.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL
    return nil unless user.length > 0
    # p user.first
    User.new(user.first) # play is stored in an array!
  end

  def self.all?
    user = QuestionsDBConnection.instance.execute(<<-SQL,)
      SELECT
        *
      FROM
        users

    SQL
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  attr_accessor :fname, :lname
  attr_reader :id

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def authored_questions
    questions = Question.find_by_author_id(@id)
    questions
    # questions.each do |question|
    #   question.body
    # end
    # nil
  end

  def followed_questions
    Question_Follow.followed_questions_for_user_id(@id)
  end

  def average_karma
    num_questions =  QuestionsDBConnection.instance.execute(<<-SQL, @id)
    SELECT
      CAST(questions_asked AS FLOAT)/likes AS Average_Likes
      FROM
      (
      SELECT
        COUNT(DISTINCT(questions.id)) AS questions_asked, COUNT(question_likes.id) AS likes
      FROM
        questions
        LEFT OUTER JOIN
        question_likes ON questions.id = question_likes.questions_id
      WHERE
        author_id = ?
      );
    SQL

    num_questions[0]["Average_Likes"]
  end

  def save
    if @id
      QuestionsDBConnection.instance.execute(<<-SQL, @fname, @lname, @id)
      UPDATE
        users
      SET
        fname = ?,
        lname = ?
      WHERE
        id = ?
      SQL
    else
      QuestionsDBConnection.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO
        users(fname, lname)
      VALUES
        (?, ?)
      SQL
      @id = QuestionsDBConnection.instance.last_insert_row_id
    end
  end


end


#=======================================

class Question

  def self.find_by_id(id)
    question = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    return nil unless question.length > 0

    Question.new(question.first) # play is stored in an array!
  end

  def self.find_by_author_id(author_id)
    question = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL
    return nil unless question.length > 0
    questions = []
    question.each_index do |q_idx|
      questions << Question.new(question[q_idx]) # play is stored in an array!
    end
    questions
  end

  def self.find_by_title(title)
    question = QuestionsDBConnection.instance.execute(<<-SQL, title)
      SELECT
        *
      FROM
        questions
      WHERE
        title = ?
    SQL
    return nil unless question.length > 0

    Question.new(question.first) # play is stored in an array!
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def self.all?
    user = QuestionsDBConnection.instance.execute(<<-SQL,)
      SELECT
        *
      FROM
        questions

    SQL
  end

  attr_accessor :title, :body, :author_id
  attr_reader :id

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def followers
    Question_Follow.followers_for_question_id(@id)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def save
    if @id
      QuestionsDBConnection.instance.execute(<<-SQL, @title, @body, @author_id, @id)
      UPDATE
        questions
      SET
        title = ?,
        body = ?,
        author_id = ?
      WHERE
        id = ?
      SQL
    else
      QuestionsDBConnection.instance.execute(<<-SQL, @title, @body, @author_id)
      INSERT INTO
        questions(title, body, author_id)
      VALUES
        (?, ?, ?)
      SQL
      @id = QuestionsDBConnection.instance.last_insert_row_id
    end
  end

end

#=======================================

class Question_Follow


  attr_accessor :questions_id, :users_id
  attr_reader :id

  def initialize(options)
    @id = options['id']
    @questions_id = options['questions_id']
    @users_id = options['users_id']
  end

  def self.followers_for_question_id(questions_id)
    followers = QuestionsDBConnection.instance.execute(<<-SQL, questions_id)
      SELECT
        users.id, users.fname, users.lname
      FROM
        question_follows
        JOIN
        users ON users.id = question_follows.users_id
      WHERE
        questions_id = ?
    SQL
    users = []
    followers.each do |follower|
      users << User.new(follower)
    end
    users
  end

  def self.followed_questions_for_user_id(user_id)
    followed_questions = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
      SELECT
        questions.title, questions.body, questions.author_id
      FROM
        question_follows
        JOIN
        questions ON questions.id = question_follows.questions_id
      WHERE
        users_id = ?
    SQL
    questions = []
    followed_questions.each do |follower|
      questions << Question.new(follower)
    end
    questions
  end

  def self.most_followed_questions(n)
    mfq = QuestionsDBConnection.instance.execute(<<-SQL, n)
      SELECT
        questions.title, questions.body, questions.author_id, COUNT(questions_id)
      FROM
        question_follows
        JOIN
        questions ON questions.id = question_follows.questions_id
      GROUP BY
        questions_id
      ORDER BY
        COUNT(questions_id) DESC
      LIMIT
        ?
    SQL
    questions = []
    mfq.each do |question|
      questions << Question.new(question)
    end
    questions
  end

  def self.most_followed(n=1)
    Question_Follow.most_followed_questions(n)
  end

end

#=======================================

class Reply

  def self.all?
    user = QuestionsDBConnection.instance.execute(<<-SQL,)
      SELECT
        *
      FROM
        replies
    SQL
  end

  def self.find_by_user_id(users_id)
    reply = QuestionsDBConnection.instance.execute(<<-SQL, users_id)
      SELECT
        *
      FROM
        replies
      WHERE
        users_id = ?
    SQL
    return nil unless reply.length > 0
    replies = []
    reply.each_index do |reply_idx|
      replies << Reply.new(reply[reply_idx]) # play is stored in an array!
    end
    replies
  end

  def self.find_by_question_id(questions_id)
    reply = QuestionsDBConnection.instance.execute(<<-SQL, questions_id)
      SELECT
        *
      FROM
        replies
      WHERE
        questions_id = ?
    SQL
    return nil unless reply.length > 0
    replies = []
    reply.each_index do |reply_idx|
      replies << Reply.new(reply[reply_idx]) # play is stored in an array!
    end
    replies
  end

  def self.find_by_parent_id(parent_id)
    reply = QuestionsDBConnection.instance.execute(<<-SQL, parent_id)
      SELECT
        *
      FROM
        replies
      WHERE
         id = ?
    SQL
    return nil unless reply.length > 0
    Reply.new(reply.first) # play is stored in an array!
  end


  attr_accessor :questions_id, :parent_id, :users_id, :body
  attr_reader :id

  def initialize(options)
    @id = options['id']
    @questions_id = options['questions_id']
    @parent_id = options['parent_id']
    @users_id = options['users_id']
    @body = options['body']
  end

  def author
    person = User.find_by_id(@users_id)
    # "#{person.fname} #{person.lname}"
    person
  end

  def question
    quest = Question.find_by_id(@questions_id)
    quest

  end

  def parent_reply
    return 'No Parent' if @parent_id.nil?
    p_reply = Reply.find_by_parent_id(@parent_id)
    p_reply
  end

  def child_replies
    all_replies = Reply.find_by_question_id(@questions_id)
    children = []
    all_replies.each do |reply|
      children << reply if reply.parent_id == @id
    end
    children
    # children.each do |child|
    #   p child.body
    # end
    # nil
  end

  def save
    if @id
      QuestionsDBConnection.instance.execute(<<-SQL, @questions_id, @parent_id, users_id, @body, @id)
      UPDATE
        replies
      SET
        questions_id = ?,
        parent_id = ?,
        users_id = ?,
        body = ?
      WHERE
        id = ?
      SQL
    else
      QuestionsDBConnection.instance.execute(<<-SQL, @questions_id, @parent_id, @users_id, @body)
      INSERT INTO
        replies(questions_id, parent_id, users_id, body)
      VALUES
        (?, ?, ?, ?)
      SQL
      @id = QuestionsDBConnection.instance.last_insert_row_id
    end
  end


end


class QuestionLike

  def self.likers_for_question_id(question_id)
    users = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        users.id, fname, lname
      FROM
        question_likes
        JOIN
        users ON users.id = question_likes.users_id
      WHERE
        question_likes.questions_id = ?
    SQL

    likers = []
    users.each do |user|
      likers << User.new(user)
    end
    likers
  end

  def self.num_likes_for_question_id(question_id)
    num_likes = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
         COUNT(users_id) AS likes
      FROM
        question_likes
      WHERE
        questions_id = ?
      GROUP BY
        questions_id

    SQL
    return 0 if num_likes.empty?
    num_likes[0]["likes"]
  end

  def self.liked_questions_for_user_id(user_id)
    num_liked_questions = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
      SELECT
         COUNT(questions_id) AS questions
      FROM
        question_likes
      WHERE
        users_id = ?
      GROUP BY
        users_id

    SQL
    return 0 if num_liked_questions.empty?
    num_liked_questions[0]["questions"]
  end

  def self.most_liked_questions(n)
    questions = QuestionsDBConnection.instance.execute(<<-SQL, n)
      SELECT
        questions.title, questions.body, questions.author_id, COUNT(*) AS likes
      FROM
        question_likes
        JOIN
          questions ON questions.id = question_likes.questions_id
      GROUP BY
        question_likes.questions_id
      ORDER BY
        likes DESC
      LIMIT
        ?
    SQL

    mlk = []
    questions.each do |question|
      mlk << Question.new(question)
    end
    mlk
  end

  attr_accessor :questions_id, :users_id
  attr_reader :id
  def initialize(options)
    @id = options['id']
    @questions_id = options['questions_id']
    @users_id = options['users_id']
  end

end
