
# ----------------------------------------------------------------------------
# 네이버 뉴스에서 검색어로 링크 수집 (TV연예, 스포츠 뉴스 제외)
# ----------------------------------------------------------------------------

# 관련 패키지를 호출합니다.
library(tidyverse)
library(magrittr)
library(httr)
library(rvest)
library(jsonlite)

# 검색어를 입력합니다.
searchWord <- '올림픽'

# 오늘 날짜를 yyyy.mm.dd 형태로 생성합니다.
today <- Sys.Date() %>% format(format = '%Y.%m.%d')
print(x = today)

# 뉴스 링크를 데이터프레임으로 반환하는 함수를 생성합니다.
getNewsDf <- function(searchWord, bgnDate, endDate, start = 1) {
  
  # HTTP 요청을 실행합니다.
  # [참고] query string에 사용된 파라미터를 모두 입력하지 않아도 됩니다.
  res <- GET(url = 'https://search.naver.com/search.naver',
             query = list(`where` = 'news', 
                          `query` = searchWord, 
                          `sort` = 0, 
                          `photo` = 0, 
                          `filed` = 0, 
                          `pd` = 3, 
                          `ds` = bgnDate, 
                          `de` = endDate,
                          `start` = start))
  
  # 뉴스를 포함하는 HTML 요소를 선택합니다.
  items <- res %>% 
    read_html() %>% 
    html_nodes(css = 'ul.list_news > li > div > div.news_area')
  
  # 네이버뉴스 링크를 수집합니다. NA인 건도 존재합니다.
  nlink <- items %>% 
    html_node(css = 'div.info_group > a:nth-child(3)') %>% 
    html_attr(name = 'href')
  
  # 뉴스 제목을 수집합니다.
  title <- items %>% 
    html_node(css = 'a.news_tit') %>% 
    html_text(trim = TRUE)
  
  # 네이버뉴스 링크와 뉴스를 원소로 갖는 데이터프레임을 생성합니다.
  df <- data.frame(nlink, title)
  
  # 데이터프레임을 반환합니다.
  return(df)
  
}

# 오늘 날짜로 테스트합니다.
test <- getNewsDf(searchWord, bgnDate = today, endDate = today, start = 1)

# test를 출력합니다.
print(x = test)


# 반복문으로 여러 페이지의 뉴스를 수집합니다.
# 웹 페이지 하단의 '2'를 클릭하면 주소창의 URI에 '&start=11'로 변경됩니다.
# starts를 생성합니다. (1부터 최대 3200까지 10 간격으로 설정합니다.)
starts <- seq(from = 1, to = 3200, by = 10)
print(x = starts)

# 원활한 강의 진행을 위해 최대 20개까지 수집하도록 설정합니다.
starts <- starts[1:2]

# 전체 뉴스 링크를 저장할 빈 데이터프레임을 생성합니다.
news <- data.frame()

# 반복문을 실행합니다.
for (i in starts) {
  
  # 현재 진행상황을 출력합니다.
  str_glue('현재 {i}번째 뉴스로 시작하는 페이지 수집 중!') %>% print()
  
  # 뉴스를 수집합니다.
  df <- getNewsDf(searchWord, bgnDate = today, endDate = today, start = i)
  
  # 결과 객체에 추가합니다.
  news <- rbind(news, df)
  
  # 1초간 쉽니다.
  Sys.sleep(time = 1)
  
}

# 결과 객체의 구조를 파악합니다.
str(object = news)

# 중복이 있는지 확인합니다. (언론사가 수정 게시하면 중복이 발생합니다!)
news %>% duplicated() %>% sum()

# 중복을 제거합니다.
news %<>% filter(!duplicated(x = .))

# 네이버뉴스(nlink)가 NA인 행도 제거합니다.
news %<>% filter(!is.na(x = nlink))

# 네이버뉴스(nlink)에서 언론사코드(oid)와 뉴스코드(aid)를 추출합니다.
# [참고] oid와 aid는 뉴스 반응과 댓글 수집에 필요합니다.
news %<>% 
  mutate(oid = str_extract(string = nlink, pattern = '(?<=oid=)\\d+'),
         aid = str_extract(string = nlink, pattern = '(?<=aid=)\\d+'))


# ----------------------------------------------------------------------------
# 뉴스 본문 수집
# ----------------------------------------------------------------------------

# 반복문을 실행할 범위를 설정합니다.
n <- nrow(x = news)

# (반복문에서 변수로 사용될) i에 1을 지정합니다.
i <- 1

# 언론사, 최종수정일시, 뉴스 본문을 저장할 컬럼을 생성합니다.
news[c('press', 'pdate', 'article')] <- NA

# 반복문을 실행합니다.
for (i in 1:nrow(x = news)) {
  
  # 현재 진행상황을 출력합니다.
  str_glue('현재 {i}번째 뉴스 정보 수집 중!') %>% print()
  
  # 에러가 발생하면 다음 뉴스로 건너뛰도록 설정합니다.
  tryCatch({
    
    # HTTP 요청을 실행합니다.
    res <- GET(url = news$nlink[i])
    
    # 언론사를 수집합니다.
    news$press[i] <- res %>% 
      read_html() %>% 
      html_node(css = 'div.press_logo > a > img') %>% 
      html_attr(name = 'title')
    
    # 기사입력, 최종수정 일시를 수집하고, 마지막 원소를 선택합니다.
    news$pdate[i] <- res %>% 
      read_html() %>% 
      html_nodes(css = 'div.sponsor > span') %>% 
      html_text(trim = TRUE) %>% 
      tail(n = 1)
    
    # 뉴스 본문을 수집합니다.
    news$article[i] <- res %>% 
      read_html() %>% 
      html_node(css = '#articleBodyContents, #newsEndContents') %>% 
      html_nodes(xpath = 'text() | p') %>% 
      html_text(trim = TRUE) %>% 
      str_c(collapse = ' ') %>% 
      str_squish()
    
  }, error = function(e) cat('-> 에러가 발생하여 다음 뉴스로 건너뜁니다!\n'))
  
  # 1초간 쉽니다.
  Sys.sleep(time = 1)
  
}

# 결과 객체의 구조를 파악합니다.
str(object = news)


# ----------------------------------------------------------------------------
# 기사 반응 수집
# ----------------------------------------------------------------------------

# 반응 관련 리소스는 Network 탭의 JS에서 'contents'로 시작합니다.
# query 파라미터 q에 'NEWS[ne_{oid}_{aid}]' 형태의 문자열을 지정해야 합니다.

# 기사 반응을 데이터프레임으로 반환하는 사용자 정의 함수를 생성합니다.
getReaction <- function(oid, aid) {
  
  # HTTP 요청을 실행합니다.
  res <- GET(url = 'https://news.like.naver.com/v1/search/contents', 
             query = list(`q` = str_glue('NEWS[ne_{oid}_{aid}]')))
  
  # JSON을 문자열로 변환한 다음, 리스트로 생성합니다.
  data <- res %>% content(as = 'text') %>% fromJSON()
  
  # 반응 데이터를 데이터프레임으로 저장합니다.
  react <- data$contents$reactions[[1]][1:2]
  
  # oid, aid와 react를 가로 방향으로 결합합니다.
  react <- cbind(oid = news$oid[i], aid = news$aid[i], react)
  
  # react를 반환합니다.
  return(react)
  
}

# 첫 번째 뉴스로 테스트합니다.
i <- 1
getReaction(oid = news$oid[i], aid = news$aid[i])

# 전체 뉴스 반응을 저장할 빈 데이터프레임을 생성합니다.
reacts <- data.frame()

# 반복문을 실행합니다.
for (i in 1:n) {
  
  # 현재 진행상황을 출력합니다.
  str_glue('현재 {i}번째 뉴스 반응 수집 중!') %>% print()
  
  # 반응을 수집합니다.
  react <- getReaction(oid = news$oid[i], aid = news$aid[i])
  
  # react는 반응이 있으면 데이터프레임, 없으면 행렬로 반환됩니다.
  # react가 데이터프레임일 때 아래 코드를 실행합니다.
  if (class(x = react)[1] == 'data.frame') {
    
    # 결과 객체에 추가합니다.
    reacts <- rbind(reacts, react)
    
  }
  
  # 1초간 쉽니다.
  Sys.sleep(time = 1)
  
}

# Long Type인 reacts를 Wide Type으로 변환합니다.
reacts %<>% spread(key = reactionType, value = count, fill = 0)

# 반응 합계를 계산합니다.
reacts %<>% mutate(reactions = angry + like + sad + want + warm)

# news와 reacts를 왼쪽 병합합니다.
news %<>% left_join(y = reacts, by = c('oid', 'aid'))


# ----------------------------------------------------------------------------
# 기사 댓글 수집
# ----------------------------------------------------------------------------

# 댓글 관련 리소스는 Network 탭의 JS에서 'web_naver_list'로 시작합니다.
# query 파라미터 objectId에 'news{oid},{aid}' 형태의 문자열을 지정해야 합니다.

# 뉴스 댓글 개수와 데이터프레임으로 반환하는 함수를 생성합니다.
getReply <- function(oid, aid, ref, page = 1) {
  
  # HTTP 요청을 실행합니다.
  res <- GET(url = 'https://apis.naver.com/',
             path = 'commentBox/cbox/web_neo_list_jsonp.json', 
             query = list(
               `ticket` = 'news', 
               `pool` = 'cbox5', 
               `lang` = 'ko', 
               `country` = 'KR', 
               `objectId` = str_glue('news{oid},{aid}'), 
               `pageSize` = 100, 
               `page` = page, 
               `sort` = 'favorite'
             ),
             add_headers(`referer` = ref))
  
  # JSON을 문자열로 변환한 다음, 리스트로 생성합니다.
  data <- res %>% 
    content(as = 'text') %>% 
    str_remove_all(pattern = '_callback\\(|\\);') %>% 
    fromJSON()
  
  # 현재 댓글 개수를 replyCnt에 할당합니다.
  replyCnt <- data$result$count$comment
  
  # 댓글 총 페이지수를 확인합니다.
  pages <- data$result$pageModel$totalPages
  
  # replyCnt가 1 이상이면 아래 코드를 실행합니다.
  if (replyCnt >= 1) {
    
    # data에서 댓글을 포함하는 데이터프레임을 df에 할당합니다.
    df <- data$result$commentList
    
    # df를 전처리합니다. (필요한 컬럼 선택)
    df %<>% select(objectId, commentNo, contents, userName, regTime)
    
    # replyCnt, pages와 df를 리스트로 반환합니다.
    return(list(replyCnt = replyCnt, pages = pages, df = df))
    
  } else {
    
    # replyCnt, pages와 빈 df를 리스트로 반환합니다.
    return(list(replyCnt = replyCnt, pages = pages, df = df))
    
  }
}

# 첫 번째 뉴스로 테스트합니다.
i <- 1
test <- getReply(oid = news$oid[i], aid = news$aid[i], ref = news$nlink[i])

# test의 구조를 확인합니다.
str(object = test)


# 댓글 전체를 데이터프레임으로 반환하는 함수를 생성합니다.
getReplies <- function(oid, aid, ref) {
  
  # 첫 번째 페이지를 수집합니다.
  first <- getReply(oid, aid, ref)
  
  # 총 댓글 개수를 replyCnt에 할당합니다.
  replyCnt <- first$replyCnt
  
  # 총 페이지수를 pages에 할당합니다.
  pages <- first$pages
  
  # 원활한 강의 진행을 위해 최대 5 페이지까지 수집하도록 설정합니다.
  pages <- min(5, pages)
  
  # 반복 작업을 실행할 페이지 수를 출력합니다.
  str_glue('> 총 댓글 개수는 {replyCnt} 입니다.') %>% print()
  str_glue('> 수집할 페이지 수는 {pages} 입니다.') %>% print()
  str_glue('>> 현재 1 페이지 실행 중!') %>% print()
  
  # 1초간 멈춥니다.
  Sys.sleep(time = 1)
  
  # 첫 번째 페이지의 데이터프레임을 dfs에 할당합니다.
  dfs <- first$df
  
  # 만약 pages가 2 이상이면 아래 코드를 실행합니다.
  if (pages >= 2) {
    
    # 반복문을 실행합니다.
    for (page in 2:pages) {
      
      # 현재 진행상황을 출력합니다.
      str_glue('>> 현재 {page} 페이지 실행 중!') %>% print()
      
      # 현재 페이지의 댓글 데이터를 수집합니다.
      current <- getReply(news$oid[i], news$aid[i], news$nlink[i], page = page)
      
      # 현재 페이지의 데이터프레임을 df에 할당합니다.
      df <- current$df
      
      # dfs에 df를 추가합니다.
      dfs <- rbind(dfs, df)
      
      # 1초간 멈춥니다.
      Sys.sleep(time = 1)
      
    }
  }
  
  # 최종 결과를 반환합니다.
  return(list(replyCnt = replyCnt, df = dfs))
  
}

# 첫 번째 뉴스로 테스트합니다.
i <- 1
test <- getReplies(oid = news$oid[i], aid = news$aid[i], ref = news$nlink[i])

# test의 구조를 확인합니다.
str(object = test)


# 댓글 개수를 저장할 컬럼을 생성합니다.
news$replyCnt <- NA

# 전체 뉴스 댓글을 저장할 빈 데이터프레임을 생성합니다.
replies <- data.frame()

# 반복문을 실행합니다.
for (i in 1:n) {
  
  # 현재 진행상황을 출력합니다.
  str_glue('현재 {i}번째 뉴스 댓글 수집 중!') %>% print()
  
  # 뉴스 댓글을 수집합니다.
  reply <- getReplies(oid = news$oid[i], aid = news$aid[i], ref = news$nlink[i])
  
  # 한 칸 띄웁니다.
  cat('\n')
  
  # 댓글 개수를 수집합니다.
  news$replyCnt[i] <- reply$replyCnt
  
  # 댓글 개수가 1 이상이면 아래 코드를 실행합니다.
  if (reply$replyCnt >= 1) {
    
    # 결과 객체에 추가합니다.
    replies <- rbind(replies, reply$df)
    
  }
  
  # 1초간 쉽니다.
  Sys.sleep(time = 1)
  
}


# ----------------------------------------------------------------------------
# 작업 결과 저장
# ----------------------------------------------------------------------------

# 현재 작업경로를 확인합니다.
getwd()

# (필요시) RDS 파일을 저장할 폴더로 작업경로를 변경합니다.
setwd(dir = './data')

# RDA 파일명을 지정합니다.
today <- format(x = Sys.Date(), format = '%Y%m%d')
fileName <- str_glue('Naver_News_{today}.RDA')

# RDA 파일로 저장합니다.
save(list = c('news', 'replies'), file = fileName)

# Environment에 있는 객체를 모두 삭제합니다.
# [주의] 아래 코드를 실행하기 전에 모두 삭제해도 좋은지 반드시 확인하세요!
rm(list = ls())

# 현재 작업경로에 저장된 폴더명과 파일명을 문자 벡터로 출력합니다.
list.files()

# RDA 파일을 읽습니다.
load(file = 'Naver_News_20210806.RDA')


## End of Document
