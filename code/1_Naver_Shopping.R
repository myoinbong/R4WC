
# ----------------------------------------------------------------------------
# 네이버 쇼핑 리뷰 수집 (1페이지)
# ----------------------------------------------------------------------------

# 관련 패키지를 호출합니다.
library(tidyverse)
library(httr)
library(rvest)

# 검색어를 설정합니다. 
searchWord <- '노트북'

# 네이버 쇼핑의 상품코드(nvMid)를 설정합니다.
# nvMid는 개별 상품 페이지의 주소창에서 확인할 수 있습니다!
nvMid <- '26529080523'

# HTTP 요청을 실행합니다.
res <- GET(
  url = str_glue('https://search.shopping.naver.com/catalog/{nvMid}'), 
  query = list(query = searchWord)
)

# HTTP 응답 결과를 확인합니다. HTML 데이터로 받았습니다.
print(x = res)

# HTML을 문자열로 출력합니다.
content(x = res, as = 'text')

# 리뷰를 포함하는 HTML 요소를 선택하고, 텍스트만 추출합니다.
res %>% 
  read_html() %>% 
  html_nodes(css = '#section_review > ul > li > div > div > p') %>% 
  html_text() -> reviews

# reviews의 원소 개수를 확인합니다.
length(x = reviews)

# reviews의 처음 2개만 출력합니다.
head(x = reviews, n = 2)


# ----------------------------------------------------------------------------
# 네이버 쇼핑 리뷰 수집 (2페이지)
# ----------------------------------------------------------------------------

# 관련 패키지를 호출합니다.
library(jsonlite)
library(magrittr)

# HTTP 요청을 실행합니다.
res <- GET(
  url = 'https://search.shopping.naver.com/api/review', 
  query = list(
    nvMid = nvMid,
    reviewType = 'ALL',
    sort = 'QUALITY',
    isNeedAggregation = 'N',
    isApplyFilter = 'N',
    page = 1,
    pageSize = 20
  )
)

# HTTP 응답 결과를 확인합니다. JSON 데이터로 받았습니다.
print(x = res)

# JSON을 문자열로 출력합니다.
content(x = res, as = 'text')

# JSON 데이터를 추출하여 리스트 객체를 생성합니다.
res %>% 
  content(as = 'text') %>% 
  fromJSON() -> data

# data의 클래스를 확인합니다.
class(x = data)

# data의 구조를 확인합니다.
str(object = data)

# data의 원소명을 확인합니다.
names(x = data)

# data의 원소별 클래스를 확인합니다.
map_chr(.x = data, .f = class)

# data의 원소별 값을 확인합니다.
data$totalCount
data$reviews

# reveiws로 데이터프레임을 생성합니다.
df <- data$reviews

# df의 행 길이를 확인합니다.
nrow(x = df)

# df의 컬럼명을 확인합니다.
colnames(x = df)

# df에서 필요한 컬럼만 선택하고, date 컬럼을 생성합니다.
df %<>% 
  select(userId, content, createTime, starScore) %>% 
  mutate(date = as.POSIXct(x = createTime / 1e3, origin = '1970-01-01'))

# df의 처음 6행을 출력합니다.
head(x = df)


## End of Document
