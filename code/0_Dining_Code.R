
# ----------------------------------------------------------------------------
# 웹 크롤링 라이브 코딩 : 다이닝코드 '스시' 맛집 수집 (1페이지)
# ----------------------------------------------------------------------------

# 관련 패키지를 호출합니다.
library(tidyverse)
library(httr)
library(rvest)

# 검색어를 지정합니다.
searchWord <- '스시'

# HTTP 요청을 실행합니다.
res <- GET(
  url = 'https://www.diningcode.com/list.php',
  query = list(query = searchWord)
)

# HTTP 응답 결과를 확인합니다. HTML 데이터로 받았습니다.
print(x = res)

# 맛집 정보를 포함하는 HTML 요소를 선택합니다.
items <- res %>% 
  read_html() %>% 
  html_nodes(css = '#div_list > li > a')

# items의 원소 개수를 확인합니다.
length(x = items)

# items의 처음 2개만 출력합니다.
head(x = items, n = 2)

# CSS Selector를 지정하면 텍스트를 반환하는 함수를 생성합니다.
getText <- function(html, css) {
  html %>% 
    html_node(css = css) %>% 
    html_text(trim = TRUE) %>% 
    return()
}

# 식당 이름을 출력합니다.
getText(html = items, css = 'span.btxt')

# 주요 메뉴를 출력합니다.
getText(html = items, css = 'span.stxt')

# 식당 소개를 출력합니다.
getText(html = items, css = 'span.ctxt')

# 식당 상권을 출력합니다.
getText(html = items, css = 'span:nth-child(5) > i')

# 데이터프레임으로 저장합니다.
df1 <- data.frame(
  name = getText(html = items, css = 'span.btxt'), 
  menu = getText(html = items, css = 'span.stxt'), 
  desc = getText(html = items, css = 'span.ctxt'), 
  area = getText(html = items, css = 'span:nth-child(5) > i')
)


# ----------------------------------------------------------------------------
# 웹 크롤링 라이브 코딩 : 다이닝코드 '스시' 맛집 수집 (2페이지)
# ----------------------------------------------------------------------------

# HTTP 요청을 실행합니다.
res <- POST(
  url = 'https://www.diningcode.com/2018/ajax/list.php',
  body = list(query = searchWord, page = 2, chunk = 10),
  encode = 'form'
)

# HTTP 응답 결과를 확인합니다. HTML 데이터로 받았습니다.
print(x = res)

# 맛집 정보를 포함하는 HTML 요소를 선택합니다.
items <- res %>% 
  read_html() %>% 
  html_nodes(css = 'a')

# items의 원소 개수를 확인합니다.
length(x = items)

# items의 처음 2개만 출력합니다.
head(x = items, n = 2)

# 데이터프레임으로 저장합니다.
df2 <- data.frame(
  name = getText(html = items, css = 'span.btxt'), 
  menu = getText(html = items, css = 'span.stxt'), 
  desc = getText(html = items, css = 'span.ctxt'), 
  area = getText(html = items, css = 'span:nth-child(5) > i')
)

# 데이터프레임을 세로 방향으로 결합합니다.
df <- rbind(df1, df2)


## End of Document 
