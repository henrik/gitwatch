class Guard
  def initialize(group_name, people, &matcher)
    @group_name = group_name
    @people = people
    @matcher = matcher
  end

  def matching_paths(paths)
    paths.select(&@matcher)
  end

  attr_reader :group_name, :people
end
