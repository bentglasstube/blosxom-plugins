class Article
  def initialize(title, category, body)
    @title = title
    @category = category
    @body = body
    @filename = Time.now.to_i
  end

  def write(basedir)
    
    
    if @category == ""
      file = File.new("#{basedir}/#{@filename}.txt", "w")
    else
      file = File.new("#{basedir}/#{@category}/#{@filename}.txt", "w")
    end
      file.print "#{@title}\nmeta-markup: textile\n#{@body}"
    return @filename
  end
  def getName
    @filename
  end
end


