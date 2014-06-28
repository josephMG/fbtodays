# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

currentPage = 1
intervalID = -1000
flag=true
$ ->
  $('.title-area input').datepicker({
    format: "yyyy/mm/dd",
    todayBtn: "linked",
    language: "zh-TW",
    todayHighlight: true,
    autoclose: true,
    endDate: new Date(),
  }).on('changeDate', (e) ->
    return false if e.dates.length==0
    since=new Date(e.date)
    from=since.getTime()/1000
    to=from+60*60*24
    $('.title-area input').hide()
    $('.title-area img').show()
    #page='page[until]='+to+'&page[since]='+from
    console.log {util:to, since:from}
    flag=false
    $("#feeds").html('')
    $.ajax {
      url:"/show",
      data:{until: to,since: from},
      type:"get",
      success: appendData
    }
  )
  $('.title-area input').datepicker('setDate',new Date())
  $('.title-area input').hide()
  $('.title-area img').show()
  $.ajax "/show",
    success: (data) ->
      img_len_old=0
      $("#feeds").append $(data).not "#next_page"
      $("#feeds").after $(data).filter "#next_page"
      img_len_new=$("img").length
#      intervalID = setInterval(checkScroll, 250)
      waterfall(img_len_old,img_len_new)
      $('.title-area input').show()
      $('.title-area img').hide()
      flag=false

$(window).resize ()->
  if $(window).width() < 641
    $(".top-bar-center a").text("FB today!")
  else
    $(".top-bar-center a").text("Facebook today!")

pageHeight = () ->
  Math.max(document.body.scrollHeight, document.body.offsetHeight)

scrollDistanceFromBottom = (argument) ->
  pageHeight() - (window.pageYOffset + self.innerHeight)

nearBottomOfPage = ()  ->
  scrollDistanceFromBottom() < 50

checkScroll = () ->
  return false
  if nearBottomOfPage() && intervalID!=-1000 && $("#progress").is(":hidden")
    $("#progress").show()
  return if flag==false
  if nearBottomOfPage()
    $('.title-area input').hide()
    $('.title-area img').show()
    flag=false
    clearInterval(intervalID)
    url = $("#next_page").val()
    jQuery.ajax url,
      {asynchronous:true, evalScripts:true, method:'get', 
      success: appendData
      }
appendData = (data, textStatus, jqXHR) ->
  count=0
  img_len_old=$("img").length
  $(data).each (key,value) -> 
    if $(value).attr("id") == "next_page"
      url=$(value).val()
      $("#next_page").val url
    else
      count++
      $("#feeds").append value
  img_len_new=$("img").length
  waterfall(img_len_old,img_len_new)
  $('#feeds').masonry('reload')
  $('.title-area input').show()
  $('.title-area img').hide()
  if count == 0
    clearInterval(intervalID)
    intervalID = -1000
  else
    intervalID = setInterval(checkScroll, 250)
    flag=true

waterfall = (img_len_old,img_len_new) ->
  len=img_len_new-img_len_old
  $("img").load () ->
    $('#feeds').masonry({
      itemSelector: '.large-4'
    })