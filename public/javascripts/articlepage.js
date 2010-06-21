var citation_info = {
  cache: {},
  open: null,
  setup: function(  ){
    $(".body_column > *[id^='p-'], .body_column > ul > li[id^='p-']").addClass("citable");
    var self = this;
    $("#content_area").bind('click', function(event) {
      if( $(event.target).hasClass("citable") ){
        event.preventDefault();
        self.show( $(event.target).attr("id") );    
      }
    });
  },
  create: function( index ){
    var id = "citation_info_" + index;
    var index_el = $("#" + index);
    var box = '<div id="' + id + '" class="pull_out citation_box"><ul><li class="link"><a href="/a/'+ $(".doc_number").text() + '/' + index +'">Link to this paragraph</a></li><li class="cite_volume"><strong>Citation</strong> ' + $(".metadata_list .volume").text() + ' FR ' + $(".metadata_list .page").text() + '</li><li class="cite_page"><strong>Page</strong> ' + $(".metadata_list .page").text() + '</li><li class="email"><a href="#">Email this</a></li><li class="twitter"><a href="#">Share this on Twitter</a></li><li class="facebook"><a href="#">Share this on Facebook</a></li><li class="digg"><a href="#">Share this on digg</a></li></ul></div>'
    $("#sidebar").append(box);
    var id_el = $("#" + id); 
    id_el.css({"top": index_el.position().top + 6, "right": 0}).data("id", index).data("sticky", false);
    this.cache[ index ] = id_el;
    return id;
  },
  show: function( id ){
    if ( this.cache[id] == null )
      this.create( id );
    if ( this.open != null && this.open != id ){
      this.hide( this.open );
      }
    this.cache[id].fadeIn();
    this.open = id;
  },
  hide: function( id ){
    this.cache[id].fadeOut();
  }
};

$(document).ready(function() {
  //   if( $("#entries.show").size() > 0 ){
  //     $("ul.table_of_graphics").before('<div id="gallery"><div id="controls"></div><div class="slideshow-container"><div id="loading"></div><div id="slideshow"></div><div id="caption"></div></div></div>');
  //     $("ul.table_of_graphics").wrap("<div id='thumbs'></div>");
  //    $('div.navigation').css({'width' : '200px', 'float' : 'left'});
  //      var gallery = $('#thumbs').galleriffic({  
  //        imageContainerSel:      '#slideshow',
  //       controlsContainerSel:   '#controls'
  //      });
  // }
  //   
  $('div.article[data-internal-id]').each(function(){
    var id = $(this).attr('data-internal-id');
    $.ajax({
      url: '/articles/views',
      type: 'POST',
      data: {'id': id}
    });
  });
  
  citation_info.setup();
  
});



