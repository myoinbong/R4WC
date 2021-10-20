
# ----------------------------------------------------------------------------
# 네이버 쇼핑 리뷰 수집
# ----------------------------------------------------------------------------

# 관련 패키지를 호출합니다.
library(tidyverse)
library(httr)
library(rvest)

# 검색어를 설정합니다. 
searchWord <- '노트북'

# HTTP 요청을 실행합니다.
res <- GET(
  url = 'https://search.shopping.naver.com/catalog/27175663523', 
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

# 리뷰를 출력합니다.
print(x = reviews)


## End of Document
