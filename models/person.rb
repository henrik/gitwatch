class Person < Struct.new(:email, :chat_name)
  @all = []

  def self.all
    @all
  end

  def self.register(email, chat_name)
    person = Person.new(email, chat_name)
    all << person
    person
  end

  def self.find_by_email(email)
    all.find { |person| person.email == email }
  end

  def at_mention
    "@#{chat_name}"
  end
end
