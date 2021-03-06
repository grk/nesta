module ModelFactory

  FIXTURE_DIR = File.join(File.dirname(__FILE__), "fixtures")

  def stub_config_key(key, value)
    @config ||= {}
    @config[key] = value
  end
  
  def stub_env_config_key(key, value)
    @config ||= {}
    @config["test"] ||= {}
    @config["test"][key] = value
  end

  def stub_configuration
    stub_config_key("title", "My blog")
    stub_config_key("subtitle", "about stuff")
    stub_config_key("description", "great web site")
    stub_config_key("keywords", "home, page")
    stub_env_config_key(
        "content", File.join(File.dirname(__FILE__), ["fixtures"]))
    Nesta::Configuration.stub!(:configuration).and_return(@config)
  end

  def create_article_with_metadata
    metadata = {
      "description" => "Page about stuff",
      "keywords" => "things, stuff",
      "date" => "29 December 2008",
      "summary" => 'Summary text\n\nwith two paragraphs',
      "read more" => "Continue please"
    }
    create_article(:metadata => metadata)
    metadata
  end

  def create_article(options = {})
    o = {
      :permalink => "my-article",
      :title => "My article",
      :content => "Content goes here"
    }.merge(options)
    path = filename(Nesta::Configuration.article_path, o[:permalink])
    create_file(path, o)
    yield(path) if block_given?
  end
  
  def create_comment(options = {})
    o = {
      :metadata => {
        "article" => "my-article",
        "date" => "Sun Nov 23 13:15:47 +0000 2008",
        "author" => "Fred Bloggs",
        "author email" => "fred@bloggs.com",
        "author url" => "http://bloggs.com/~fred"
      },
      :content => "Great article."
    }.merge(options)
    basename = Comment.basename(
        DateTime.parse(o[:metadata]["date"]), o[:metadata]["author"])
    path = filename(Nesta::Configuration.comment_path, basename)
    create_file(path, o)
    yield(path) if block_given?
  end
  
  def create_category(options = {})
    o = {
      :permalink => "my-category",
      :title => "My category",
      :content => "Content goes here"
    }.merge(options)
    path = filename(Nesta::Configuration.category_path, o[:permalink])
    create_file(path, o)
    yield(path) if block_given?
  end
  
  def delete_page(type, permalink)
    path = Nesta::Configuration.send "#{type}_path"
    FileUtils.rm(filename(path, permalink))
  end
  
  def remove_fixtures
    FileUtils.rm_r(FIXTURE_DIR, :force => true)
  end
  
  def create_content_directories
    FileUtils.mkdir_p(Nesta::Configuration.article_path)
    FileUtils.mkdir_p(Nesta::Configuration.attachment_path)
    FileUtils.mkdir_p(Nesta::Configuration.category_path)
    FileUtils.mkdir_p(Nesta::Configuration.comment_path)
  end
  
  def mock_file_stat(method, filename, time)
    stat = mock(:stat)
    stat.stub!(:mtime).and_return(Time.parse(time))
    File.send(method, :stat).with(filename).and_return(stat)
  end

  private
    def filename(directory, basename)
      File.join(directory, "#{basename}.mdown")
    end
    
    def create_file(path, options = {})
      create_content_directories
      metadata = options[:metadata] || {}
      metatext = metadata.map { |key, value| "#{key}: #{value}" }.join("\n")
      title = options[:title] ? "# #{options[:title]}\n\n" : ""
      contents =<<-EOF
#{metatext}

#{title}#{options[:content]}
      EOF

      File.open(path, "w") { |file| file.write(contents) }
    end
end
