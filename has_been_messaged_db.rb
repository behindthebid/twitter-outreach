class HasBeenMessagedDb
  FILE_NAME = 'already_messaged.txt'
  def initialize
    handles = File.exists?(FILE_NAME) ? File.readlines(FILE_NAME).map(&:strip) : []
    @db = Set.new(handles)
  end

  def set_has_been_messaged(handle)
    @db.add(handle)
    File.open(FILE_NAME, "a") {|f| f.write("#{handle}\n") }
  end

  def already_messaged?(handle)
    @db.include?(handle)
  end
  
end