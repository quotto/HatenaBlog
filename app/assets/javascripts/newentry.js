var newentry_url="http://hatenablog.wackwack.net/hatena_blog/newentry";
$.ajax({
  type:"GET",
  url:newentry_url,
  datatype:"json",
  success:function(a,b){
    entries=a.articles;
    $div_hatena_module=$('<div class="hatena-module hatena-module-new-entries"></div>');
    $div_hatena_module_title=$('<div class="hatena-module-title"><a href="http://blog.hatena.ne.jp/-/recent">はてなブログの新着エントリー</a></div>');
    $div_hatena_module_body=$('<div class="hatena-module-body"></div>');
    $ul_hatena_urllist=$('<ul class="hatena-urllist"></ul>');
    for(var c=0;c<entries.length;c++) {
      $li_hatena_newentrylist=$('<li class="hatena-newentrylist"></li>');
      $div_title=$('<div class="hatena-newentry-title"><a href="'+entries[c].href+'">'+entries[c].title+"</a></div>");
      $div_article=$('<div class="hatena-newentry-article">'+entries[c].article+"</div>");
      $div_footer=$('<div class="hatena-newentry-footer"><a href="'+entries[c].href+'">'+entries[c].user+'</a> - <span>' + entries[c].time + '</span></div>');
      $li_hatena_newentrylist.append($div_title);
      $li_hatena_newentrylist.append($div_article);
      $li_hatena_newentrylist.append($div_footer);
      $ul_hatena_urllist.append($li_hatena_newentrylist);
      $div_hatena_module_body.append($ul_hatena_urllist);
    }
    $div_hatena_module.append($div_hatena_module_title);
    $div_hatena_module.append($div_hatena_module_body);
    $("#box2-inner").append($div_hatena_module);
  }
});

