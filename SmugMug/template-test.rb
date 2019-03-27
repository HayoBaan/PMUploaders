

class SmugMugFileUploaderTests
  def initialize(uploader_template)
    @up = uploader_template
    @bridge = @up.instance_eval{ @bridge }
  end
  
  def run
    dbgprint "************ run ***************************"
    AlbumParseTest.new(@bridge).run
    CategoryParseTest.new(@bridge).run
  end
end

class AlbumParseTest
  include TemplateUnitTestAsserts

  def initialize(bridge)
    @bridge = bridge
  end

  def run
    test_album_parse
  end

  def test_album_parse
    albums = SmugMugAlbumList.new(@bridge, raw_album_list_response)
    assert_equal( 5, albums.count )
    uniq_titles = albums.collect {|album| album.unique_title}    
    expected_titles = [
      "Funky Broadway",
      "Funky Broadway (2)",
      "hootenanny",
      "cbits-test",
      "Fabulous me!"
    ]
    assert_equal( expected_titles, uniq_titles )
    album = albums.find_by_unique_title("Bogus Name")
    assert_equal( nil, album )
    album = albums.find_by_unique_title("Funky Broadway (2)")
    assert_equal( "Funky Broadway", album.title )
    assert_equal( "8132904", album.album_id )
    assert_equal( "Pv4Vs", album.album_key )
    assert_equal( "48", album.category_id )
    assert_equal( "Dance", album.category_name )
    assert_equal( "Funky Broadway (2)", album.unique_title )
  end

  protected

  def raw_album_list_response
<<ENDTXT
<?xml version="1.0" encoding="utf-8"?>
<rsp stat="ok">
  <method>smugmug.albums.get</method>
  <Albums>
    <Album id="8132906" Key="zAhaQ" Title="Funky Broadway">
      <Category id="48" Name="Dance"/>
    </Album>
    <Album id="8132904" Key="Pv4Vs" Title="Funky Broadway">
      <Category id="48" Name="Dance"/>
    </Album>
    <Album id="7406801" Key="LEyeR" Title="hootenanny">
      <Category id="24" Name="Video Games"/>
    </Album>
    <Album id="7339542" Key="XL9XZ" Title="cbits-test">
      <Category id="27" Name="Photography"/>
    </Album>
    <Album id="7226729" Key="pgaM2" Title="Fabulous me!">
      <Category id="0" Name="Other"/>
    </Album>
  </Albums>
</rsp>
ENDTXT
  end
end


class CategoryParseTest
  include TemplateUnitTestAsserts

  def initialize(bridge)
    @bridge = bridge
  end

  def run
    test_category_parse
  end

  def test_category_parse
    categories = SmugMugCategoryList.new(@bridge, raw_category_list_response)
    assert_equal( 8, categories.count )
    names = categories.collect {|category| category.name}    
    expected_names = [
      "Other",
      "Airplanes",
      "Animals",
      "Aquariums",
      "Architecture",
      "Art",
      "Arts and Crafts",
      "Video Games"
    ]
    assert_equal( expected_names, names )
    category = categories.find_by_name("Bogus Name")
    assert_equal( nil, category )
    category = categories.find_by_name("Video Games")
    assert_equal( "Video Games", category.name )
    assert_equal( "24", category.category_id )
  end

  protected

  def raw_category_list_response
<<ENDTXT
<rsp stat="ok">
  <method>smugmug.categories.get</method>
  <Categories>
    <Category id="0" Title="Other"/>
    <Category id="41" Title="Airplanes"/>
    <Category id="1" Title="Animals"/>
    <Category id="25" Title="Aquariums"/>
    <Category id="2" Title="Architecture"/>
    <Category id="3" Title="Art"/>
    <Category id="43" Title="Arts and Crafts"/>
    <Category id="24" Title="Video Games"/>
  </Categories>
</rsp>
ENDTXT
  end
end
