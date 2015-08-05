require 'crawler_rocks'
require 'json'
require 'pry'

class NationalTaiwanSportUniversityCrawler

 def initialize year: nil, term: nil, update_progress: nil, after_each: nil

  @year = year-1911
  @term = term
  @update_progress_proc = update_progress
  @after_each_proc = after_each

  @query_url = "http://one.ntsu.edu.tw/ntsu/outside.aspx"
  @result_url = "http://one.ntsu.edu.tw/NTSU//Application/TKE/TKE22/TKE2210_01.aspx"
 end

 def courses
  @courses = []

# 有時候網頁會連不上，多跑個幾次試試看
  r = RestClient.get(@query_url)
  cookie = "citrix_ns_id=#{r.cookies["citrix_ns_id"]}; ASP.NET_SessionId=#{r.cookies["ASP.NET_SessionId"]}"

  r = RestClient.get(@result_url, {"Cookie" => cookie })
  doc = Nokogiri::HTML(r)

  hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]
  @as_fid = doc.css('input[name="as_fid"]').map{|a| a[:value]}[0]

  if @year.to_s != doc.css('span[id="AYEAR"]').text
   r = post(hidden, @year, doc.css('span[id="SMS"]').text, cookie, "Q_AYEAR")

   hidden = Hash[r.split('hiddenField')[1..-1].map{|hidden| [hidden.split('|')[1], hidden.split('|')[2]]}]
  end

  if @term.to_s != doc.css('span[id="SMS"]').text
   r = post(hidden, @year, @term, cookie, "Q_SMS")

   hidden = Hash[r.split('hiddenField')[1..-1].map{|hidden| [hidden.split('|')[1], hidden.split('|')[2]]}]
  end

  r = post(hidden, @year, @term, cookie, "QUERY_BTN1", qUERY_BTN1: "QUERY_BTN1", qUERY_TYPE: 1, qUERY_BTN1_opt: "開課單位查詢", page_size: 2000)
  doc = Nokogiri::HTML(r)

  doc.css('table[id="DataGrid"] tr:not(:first-child)').map{|tr| tr}.each do |tr|
   data = tr.css('td').map{|td| td.text}

   course = {
    year: @year,
    term: @term,
    list_code: data[0],              # 序號
    # year_term: data[1],            # 學期
    general_code: data[2],           # 課號
    name: data[3],                   # 課程名稱
    department: data[4],             # 開課系所
    degree: data[5],                 # 年級班別
    lecturer: data[6],               # 任課教師
    lecturer_department: data[7],    # 教師聘任單位
    credits: data[8],                # 學分數
    required: data[9],               # 選別 (必選修)
    day: data[10],                   # 上課時間
    location: data[11],              # 上課教室
    people: data[12],                # 人數
    people_limit: data[13],          # 人數上下限
    intern: data[14],                # 實習(應該是時數)
    hours: data[15],                 # 時數
    mix: data[16],                   # 合開
    department_term: data[17],       # 期限(學期or學年)
    }

   @after_each_proc.call(course: course) if @after_each_proc

   @courses << course
  # binding.pry
  end
  @courses
 end

 def post(hidden, year, term, cookie, scriptManager1, qUERY_BTN1: nil, qUERY_TYPE: nil, qUERY_BTN1_opt: nil, page_size: 20)
  r = RestClient.post(@result_url, {
   "ScriptManager1" => "AjaxPanel|#{scriptManager1}",
   # "__EVENTTARGET" => scriptManager1,
   # "__EVENTARGUMENT" => "",
   # "__LASTFOCUS" => "",
   "__VIEWSTATE" => hidden["__VIEWSTATE"],
   "__VIEWSTATEGENERATOR" => "13021BF5",
   "__VIEWSTATEENCRYPTED" => "",
   "__EVENTVALIDATION" => hidden["__EVENTVALIDATION"],
   # "ActivePageControl" => "",
   # "ColumnFilter" => "",
   # "SAYEAR" => "",
   "QUERY_TYPE" => "#{qUERY_TYPE}",
   "FacultyType" => "2",
   "TabCnt" => "1",
   "Q_AYEAR" => year,
   "Q_SMS" => term,
   "QUERY_TYPE1" => "1",
   # "Q_DEGREE_CODE" => "",
   # "Q_COLLEGE_CODE" => "",
   # "Q_FACULTY_CODE" => "",
   # "Q_GRADE" => "",
   # "Q_CLASSID" => "",
   "PC$PageSize" => page_size,
   "PC$PageNo" => "1",
   "PC2$PageSize" => page_size,
   "PC2$PageNo" => "1",
   "as_fid" => @as_fid,
   "__ASYNCPOST" => "true",
   "#{qUERY_BTN1}" => "#{qUERY_BTN1_opt}",
   }, {
    "Cookie" => cookie,
    # "Origin" => "http://one.ntsu.edu.tw",
    # "Accept-Encoding" => "gzip, deflate",
    # "Accept-Language" => "zh-TW,zh;q=0.8,en-US;q=0.6,en;q=0.4,zh-CN;q=0.2",
    "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/43.0.2357.130 Chrome/43.0.2357.130 Safari/537.36",
    # "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8",
    # "Accept" => "*/*",
    # "Cache-Control" => "no-cache",
    # "X-Requested-With" => "XMLHttpRequest",
    # "Connection" => "keep-alive",
    # "X-MicrosoftAjax" => "Delta=true",
    # "Referer" => "http://one.ntsu.edu.tw/NTSU//Application/TKE/TKE22/TKE2210_01.aspx",
    })
 end
end

# crawler = NationalTaiwanSportUniversityCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
