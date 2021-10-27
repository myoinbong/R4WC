
# ----------------------------------------------------------------------------
# 네이버 카페에서 검색어로 링크 수집 (1 페이지)
# ----------------------------------------------------------------------------

# 관련 패키지를 호출합니다.
library(tidyverse)
library(magrittr)
library(httr)
library(rvest)
library(jsonlite)

# 검색어를 설정합니다.
searchWord <- '노트북'

# 오늘 날짜를 yyyymmdd 형태로 생성합니다.
today <- format(x = Sys.Date(), format = '%Y%m%d')
print(x = today)

# POST 방식은 Query String 대신 Body를 설정합니다.
body <- list(
  exceptMarketArticle = 1,
  page = 1,
  period = list(today, today),
  query = searchWord,
  sortBy = 0
)

# 이번 예제에서는 Body를 Payload(JSON 형태)로 전달해야 합니다.
# 따라서 Body에 속한 항목을 리스트로 생성하고 toJSON() 함수로 변환합니다.
# auto_unbox = TRUE를 생략하면 값(value)을 대괄호로 감싸게 됩니다.
body %<>% toJSON(auto_unbox = TRUE)

# body를 출력합니다.
print(x = body)

# HTTP 요청을 실행합니다.
# [주의] 네이버 블로그와 다르게 accept 대신 content-type을 추가해야 합니다!
res <- POST(
  url = 'https://apis.naver.com',
  path = '/cafe-home-web/cafe-home/v1/search/articles', 
  body = body,
  add_headers(
    `content-type` = 'application/json;charset=UTF-8',
    `referer` = 'https://cafe.naver.com/ca-fe/home/search/articles',
    `user-agent` = 'Mozilla/5.0 Chrome/90.0.4430.212'
  )
)

# HTTP 응답 결과를 확인합니다. JSON 데이터로 받았습니다.
print(x = res)

# JSON을 문자열로 변환한 다음, 리스트로 생성합니다.
data <- res %>% content(as = 'text') %>% fromJSON()

# data에서 검색 결과 개수를 totalCnt에 할당합니다.
totalCnt <- data$message$result$totalCount
print(x = totalCnt)

# data에서 검색 결과 데이터프레임을 df에 할당합니다.
df <- data$message$result$searchResultArticle$searchResult

# df에서 필요한 컬럼만 선택합니다.
df %<>% 
  select(articleid, clubid, clubname, rawWriteDate, subject)

# rawWriteDate 컬럼을 POSIX 자료형으로 변경합니다.
df %<>% 
  mutate(rawWriteDate = as.POSIXct(x = rawWriteDate, format = '%Y%m%d'))

# df의 구조를 파악합니다. 
str(object = df)


# ----------------------------------------------------------------------------
# 검색 결과 개수와 데이터프레임을 반환하는 함수 생성
# ----------------------------------------------------------------------------

getCafeDf <- function(searchWord, bgnDate, endDate, page = 1) {
  
  # 요청 Body를 설정합니다.
  body <- list(
    exceptMarketArticle = 1,
    page = page,
    period = list(bgnDate, endDate),
    query = searchWord,
    sortBy = 0
  ) %>% 
    toJSON(auto_unbox = TRUE)
  
  # HTTP 요청을 실행합니다.
  res <- POST(
    url = 'https://apis.naver.com',
    path = '/cafe-home-web/cafe-home/v1/search/articles', 
    body = body,
    add_headers(
      `content-type` = 'application/json;charset=UTF-8',
      `referer` = 'https://cafe.naver.com/ca-fe/home/search/articles',
      `user-agent` = 'Mozilla/5.0 Chrome/90.0.4430.212'
    )
  )
  
  # JSON 데이터를 처리합니다.
  data <- res %>% content(as = 'text') %>% fromJSON()
  
  # data에서 검색 결과 개수를 totalCnt에 할당합니다.
  totalCnt <- data$message$result$totalCount
  
  # totalCnt가 1 이상이면 아래 코드를 실행합니다.
  if (totalCnt >= 1) {
    
    # data에서 검색 결과 데이터프레임을 df에 할당합니다.
    df <- data$message$result$searchResultArticle$searchResult
    
    # df를 전처리합니다. (필요한 컬럼 선택 및 자료형 변경)
    df %<>% 
      select(articleid, clubid, clubname, rawWriteDate, subject) %>% 
      mutate(rawWriteDate = as.POSIXct(x = rawWriteDate, format = '%Y%m%d'))
    
    # totalCnt와 df를 리스트로 반환합니다.
    return(list(totalCnt = totalCnt, df = df))
    
  } else {
    
    # totalCnt와 빈 df를 리스트로 반환합니다.
    return(list(totalCnt = totalCnt, df = NULL))
    
  }
}

# 2 페이지로 테스트합니다.
test <- getCafeDf(searchWord, bgnDate = today, endDate = today, page = 2)

# test의 구조를 확인합니다.
str(object = test)


# ----------------------------------------------------------------------------
# 검색 결과 전체 데이터프레임을 반환하는 함수 생성
# ----------------------------------------------------------------------------

getCafeDfs <- function(searchWord, bgnDate, endDate) {
  
  # 첫 번째 페이지를 수집합니다.
  first <- getCafeDf(searchWord, bgnDate, endDate)
  
  # 검색 결과 개수를 totalCnt에 할당합니다.
  totalCnt <- first$totalCnt
  
  # 검색 결과 개수를 10으로 나누고, 올림하여 pages에 할당합니다.
  pages <- ceiling(x = totalCnt / 10)
  
  # 원활한 강의 진행을 위해 최대 5 페이지까지 수집하도록 설정합니다.
  pages <- min(5, pages)
  
  # 반복 작업을 실행할 페이지 수를 출력합니다.
  str_glue('> 총 카페글 개수는 {totalCnt} 입니다.') %>% print()
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
      
      # 현재 페이지의 데이터프레임을 수집합니다.
      current <- getCafeDf(searchWord, bgnDate, endDate, page = page)
      
      # 현재 페이지의 데이터프레임을 df에 할당합니다.
      df <- current$df
      
      # dfs에 df를 추가합니다.
      dfs <- rbind(dfs, df)
      
      # 1초간 멈춥니다.
      Sys.sleep(time = 1)
      
    }
  }
  
  # 최종 결과를 반환합니다.
  return(dfs)
  
}

# 오늘 날짜로 테스트합니다.
cafe <- getCafeDfs(searchWord, bgnDate = today, endDate = today)


# ----------------------------------------------------------------------------
# 검색어와 수집 기간을 정해 카페글 요약 데이터와 링크 수집
# ----------------------------------------------------------------------------

# 조회시작일자와 조회종료일자를 Date 자료형으로 설정합니다.
# [참고] Date 자료형은 정수이므로 산술연산이 가능합니다.
# bgnDate <- as.Date(x = '2021-01-01')
# endDate <- as.Date(x = '2021-01-03')

# 작업일 기준으로 조회시작일자와 조회종료일자를 설정합니다.
bgnDate <- Sys.Date() - 2
endDate <- Sys.Date()

# 조회시작일자와 조회종료일자로 dates를 생성합니다.
dates <- seq(from = bgnDate, to = endDate, by = '1 day')
print(x = dates)

# 최종 결과를 저장할 빈 데이터프레임을 생성합니다.
cafes <- data.frame()

# 반복문을 실행합니다.
for (date in dates) {
  
  # date를 날짜 벡터로 강제 변환합니다.
  # [참고] Date 자료형은 중괄호 안에서 정수로 강제 변환됩니다.
  date <- date %>% as.Date(origin = '1970-01-01')
  
  # 현재 진행상황을 출력합니다.
  date4print <- date %>% format(format = '%Y년 %m월 %d일')
  str_glue('현재 {date4print}에 등록된 카페글 수집 중') %>% print()
  
  # date를 문자 벡터로 강제 변환합니다.
  # [참고] 웹 서버가 요구하는 형태의 문자열로 변환해야 합니다.
  date <- date %>% format(format = '%Y%m%d')
  
  # 해당 일자에 등록된 모든 카페글을 수집합니다.
  cafe <- getCafeDfs(searchWord, bgnDate = date, endDate = date)
  
  # 최종 결과 객체에 추가합니다.
  cafes <- rbind(cafes, cafe) 
  
  # 1초간 멈춥니다.
  Sys.sleep(time = 1)
  
}

# 최종 결과 객체의 구조를 파악합니다.
str(object = cafes)


# ----------------------------------------------------------------------------
# 카페글 본문 수집
# ----------------------------------------------------------------------------

# 방금 수집한 네이버 카페글 링크로 접속하면 apis로 시작하는 링크가 확인됩니다.
# 따라서 apis로 시작하는 url을 별도로 만들어서 HTTP 요청을 실행해야 합니다.
postUrl <- 'https://apis.naver.com/cafe-web/cafe-articleapi/cafes'
cafes$url <- str_glue('{postUrl}/{cafes$clubid}/articles/{cafes$articleid}')

# 반복문을 실행할 범위를 설정합니다.
# 원활한 강의 진행을 위해 최대 5개까지 수집하도록 설정합니다.
n <- min(5, nrow(x = cafes))

# (반복문에서 변수로 사용될) i에 1을 지정합니다.
i <- 1

# 카페글 본문을 저장할 컬럼을 생성합니다.
cafes$body <- NA

# 반복문을 실행합니다.
for (i in 1:n) {
  
  # 현재 진행상황을 출력합니다.
  str_glue('현재 {i}번째 카페글 본문 수집 중!') %>% print()
  
  # HTTP 요청을 실행합니다.
  res <- GET(
    url = cafes$url[i], 
    add_headers(
      `referer` = 'https://cafe.naver.com/ca-fe/home/search/articles'
    )
  )
  
  # JSON 형태의 데이터를 선택합니다.
  data <- res %>% content(as = 'text') %>% fromJSON()
  
  # 카페 멤버에게만 공개되는 글은 로그인하지 않았을 때 NULL값이 반환됩니다.
  # 따라서 조건문을 추가하여 카페글 본문이 NULL이면 생략하도록 합니다.
  if (!is.null(x = data$article$content)) {
    
    # 카페글 본문을 저장합니다.
    cafes$body[i] <- data$article$content %>% 
      str_remove_all(pattern = '(<.+?>)|(&.+?;)') %>% 
      str_squish()
    
  }
  
  # 1초간 멈춥니다.
  Sys.sleep(time = 1)
  
}

# 카페글 본문이 NA인 건수를 확인합니다.
cafes$body %>% is.na() %>% sum()

# 카페글 본문이 NA인 행을 확인합니다.
loc <- cafes$body %>% is.na() %>% which()
print(x = loc)

# 카페글 본문의 글자수 범위를 확인합니다.
range(x = nchar(x = cafes$body), na.rm = TRUE)


# ----------------------------------------------------------------------------
# 작업 결과 저장
# ----------------------------------------------------------------------------

# 현재 작업경로를 확인합니다.
getwd()

# (필요시) RDS 파일을 저장할 폴더로 작업경로를 변경합니다.
setwd(dir = './data')

# RDS 파일명을 지정합니다.
today <- format(x = Sys.Date(), format = '%Y%m%d')
fileName <- str_glue('Naver_Cafe_{today}.RDS')

# RDS 파일로 저장합니다.
saveRDS(object = cafes, file = fileName)


## End of Document
