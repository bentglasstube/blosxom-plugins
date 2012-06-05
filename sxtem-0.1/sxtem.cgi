#!/usr/local/bin/ruby

######################################
###	Sxtem v 0.01 - 
###	remote weblog API for Bloxsom
###	(c)2003 Keith Hudgins
###	Licensed under the GPL
###	http://www.gnu.org/copyleft/gpl.html
###
###
###	Sxtem home:
###	http:///www.greenman.org/projects/sxtem
###	greenman@greenman.org
###	Requires: xml4r
######################################

### First we set local variables
### Please edit this to fit your 
### Blosxom install
datadir = "/path/to/your/data"
user = "user"
pass = "pass"
blogname = "My Blog"
blogurl = "http://my_blog.org"





#### Now some local functions
blogid = "42"
require "Article.rb"

def parseContent(content)
  @content = content
  @content =~ /<title>(.*)<\/title>/
  @title = $1
  @content = "#{$`}#{$'}"
  @content =~ /<category>(.*)<\/category>/
  @category = $1
  @content = "#{$`}#{$'}"
  STDERR.print "#{@title}\t#{@category}\t#{@content}\n"
  return [@title, @category, @content]
end

def getCategories(datadir)
  @datadir = datadir
  @categories = `find #{@datadir} -type d -print`
  @categories.gsub!(datadir, "")
  @list = @categories.split("\n")
  @list.delete("")
  return @list
end


require "xmlrpc/server"

s = XMLRPC::CGIServer.new

s.add_handler("blogger.newPost") do |appkey, blogid, username, password, content, publish|
  if username == user && password == pass
    @details = parseContent(content)
    @me = Article.new(@details[0], @details[1], @details[2])
    @me.write(datadir)
  else
    raise XMLRPC::FaultException.new(3, "Oops, user and pass don't match")
  end
end

s.add_handler("metaWeblog.getCategories") do |appkey, username, password|
if username == user && password == pass 
      @cats = getCategories(datadir)
      @return = Array.new
      @cats.each do |dir|
	@return.push({ "description" => dir,
			"htmlUrl" => blogurl,
			"rssUrl" => "#{blogurl}.rss",
			"title" => dir,
			"categoryId" => dir
		      })
      end
      @return
  else
    raise XMLRPC::FaultException.new(4, "Oops, user and pass don't match")
  end
end

s.add_handler("blogger.getUsersBlogs") do |appkey, username, password|
if username == user && password == pass 
  	[{	"url" => blogurl,
		"blogid" => blogid,
		"blogname" => blogname
      }]
  else
    raise XMLRPC::FaultException.new(4, "Oops, user and pass don't match")
  end
end


s.set_default_handler do |name, *args|
  raise XMLRPC::FaultException.new(-99, "Method #{name} missing" +
  				" or wrong number of parameters!")
end

s.serve
  


