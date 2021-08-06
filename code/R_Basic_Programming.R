
# ----------------------------------------------------------------------------
# R 자료형 및 자료구조
# ----------------------------------------------------------------------------

# 실수형 벡터를 생성합니다.
a <- c(1, 2, 3)
print(x = a)
class(x = a)

# 정수형 벡터를 생성합니다.
b <- c(1L, 2L, 3L)
print(x = b)
class(x = b)

# 문자형 벡터를 생성합니다.
c <- c('hello', 'world')
print(x = c)
class(x = c)

# 논리형 벡터를 생성합니다.
d <- c(FALSE, TRUE)
print(x = d)
class(x = d)

# 문자형 벡터로 범주형 벡터를 생성합니다.
e <- factor(x = c)
print(x = e)
class(x = e)

# [참고] as.**() 함수를 사용할 수 있습니다.
as.factor(x = c)
as.integer(x = e)
as.numeric(x = e)

# 벡터의 강제변환을 실습합니다.
f <- c(d, e)
print(x = f)
class(x = f)

f <- c(f, 3)
print(x = f)
class(x = f)

f <- c(f, '4')
print(x = f)
class(x = f)


# 간격이 일정한 숫자 벡터를 생성합니다.
seq(from = 1, to = 3, by = 1)
seq(from = 3, to = 1, by = -1)
seq(from = 1, to = 10, by = 2.5)

# 원소가 반복된 숫자 벡터를 생성합니다.
rep(x = 1:3, times = 10)
rep(x = 1:3, each = 10)


# 벡터 뒤 대괄호 안에 선택할 원소의 인덱스를 지정하면 해당 원소를 출력합니다.
letters[1]
letters[2]
letters[26]

# 벡터의 슬라이싱은 콜론을 이용하여 벡터의 연속된 원소를 선택하는 것입니다.
s <- letters[1:5]
print(x = s)

# 대괄호 안에 숫자형 벡터를 지정하면, 연속하지 않는 원소를 선택할 수 있습니다.
s[c(1, 3, 5)]

# 대괄호 안에 논리형 벡터를 지정하면, TRUE 위치에 해당하는 원소를 선택합니다.
s[c(TRUE, FALSE, TRUE, FALSE, TRUE)]
s[c(T, F, T, F, T)]


# 벡터 인덱싱을 이용하여 원소를 추가합니다.
s[10] <- 'j'
print(x = s)

# 인덱스 앞에 마이너스를 추가하면 해당 원소를 삭제한 결과를 출력합니다.
s[-10]
print(x = s)
s <- s[-10]
print(x = s)

# 인덱싱과 슬라이싱을 이용하여 원하는 위치에 있는 원소를 변경합니다.
s[1] <- 'A'
print(x = s)
s[2] <- 'B'
print(x = s)
s[c(1, 2)] <- c('AA', 'BB')
print(x = s)


# 원소 개수가 3인 벡터 a와 b를 각각 생성합니다.
a <- seq(from = 0, to = 4, by = 2)
b <- 1:3

# 원소 개수가 같은 두 벡터로 덧셈 및 뺄셈 연산을 실행합니다.
a + b
a - b

# 원소 개수가 같은 두 벡터로 곱셈 및 나눗셈 연산을 실행합니다.
a * b
a / b

# 숫자형 벡터에 대해 상수로 나머지/몫/거듭제곱을 반환하는 연산을 실행합니다.
a %% 3
a %/% 2
a ^ 2

# 숫자형 벡터에 대해 상수로 비교 연산자를 실습합니다.
a > 2
a >= 2
a < 2
a <= 2
a == 2
a != 2

# 비교 연산을 실행하여 TRUE/FALSE 여부를 확인합니다.
a >= 1; b <= 2

# 논리곱, 논리합, 논리부정 연산을 실행합니다.
a >= 1 & b <= 2
a >= 1 | b <= 2
!(a >= 1 | b <= 2)

# 논리합 연산자를 2번 이상 사용하면 코드가 매우 길어집니다.
x <- 0
x == a[1] | x == a[2] | x == a[3]

# 멤버 연산자 %in%를 사용하면 위 코드를 간단하게 처리할 수 있습니다.
x %in% a
x %in% b


# 리스트의 원소로 사용될 벡터 2개를 각각 생성합니다.
num <- seq(from = 1, to = 10, by = 2)
cha <- rep(x = c('a', 'b'), each = 3)

# 원소명을 추가한 리스트를 생성합니다.
lst <- list(a = num, b = cha)
print(x = lst)
class(x = lst)
str(object = lst)

# 리스트의 원소를 선택할 때 겹대괄호 안에 인덱스를 단 하나만 지정합니다.
lst[[1]]
lst[[2]]

# 리스트에 원소명이 있으면 $를 대신 사용하는 것이 편리합니다.
lst$a
lst$b

# 리스트의 새로운 원소명에 객체를 할당하는 방식으로 원소를 추가합니다.
lst$c <- 1:5

# 리스트에서 삭제할 원소명에 NULL을 할당하는 방식으로 해당 원소를 삭제합니다.
lst$a <- NULL

# 리스트에서 변경할 원소명에 객체를 할당하면 원소 전체가 변경됩니다.
lst$b <- letters[1:5]

# 리스트에서 변경할 원소의 일부만 변경하는 것도 가능합니다.
lst$b[1] <- 'A'


# 벡터 num과 원소 개수가 같은 벡터 cha를 생성합니다.
cha <- letters[1:5]

# 열벡터의 원소 개수가 같아야 데이터프레임이 생성됩니다.
df1 <- data.frame(num, cha)
print(x = df1)
class(x = df1)
str(object = df1)

# 대괄호 안에 행과 열 인덱스를 지정하여 해당 위치의 원소를 선택합니다.
df1[1, 1]
df1[1, ]
df1[1:2, ]
df1[, 1]
df1[, 1:2]
df1[, 'num']
df1$num

# 데이터프레임도 불리언 인덱싱을 활용할 수 있습니다.
df1$num >= 3
df1[df1$num >= 3, ]
df1[df1$num >= 3, 'cha']
df1$cha[df1$num >= 3]
df1$cha[df1$num >= 3 & df1$num <= 3]
df1$num[df1$cha %in% c('a', 'b')]

# 기존 데이터프레임의 오른쪽으로 열을 추가합니다.
cbind(df1, int = 1:5)

# 데이터프레임의 새로운 열이름에 벡터를 할당하는 방식으로 열을 추가합니다.
df1$int <- 1:5

# 기존 데이터프레임에 아래로 행을 추가합니다.
df2 <- data.frame(num = 11, cha = 'f', int = 6)
rbind(df1, df2)

# 인덱스 앞에 마이너스를 추가하면 해당 행 또는 열을 삭제한 결과를 출력합니다.
df1[-1, -1]
df1[-1, ]
df1[, -1]

# 데이터프레임에서 삭제할 열이름에 NULL을 할당하면 해당 열벡터를 삭제합니다.
df1$num <- NULL
print(x = df1)

# 데이터프레임에서 변경할 열이름에 열벡터를 할당하면 모든 원소가 변경됩니다.
df1$cha <- LETTERS[1:5]
print(x = df1)

# 데이터프레임에서 변경할 열벡터의 일부만 변경하는 것도 가능합니다.
df1$int[1] <- '1'
str(object = df1)


# ----------------------------------------------------------------------------
# R 문법
# ----------------------------------------------------------------------------

# if 조건문은 괄호 안 조건에 따라 실행할 코드를 분기합니다.
if (class(x = '1') == 'integer') {
  print(x = '정수입니다!')
} else if (class(x = '1') == 'numeric') {
  print(x = '실수입니다!')
} else {
  print(x = '숫자가 아닙니다!')
}


# 반복 실행할 값을 원소로 갖는 벡터를 미리 생성합니다.
menu <- c('짜장면', '탕수육', '깐풍기', '짬뽕', '전가복')

# for 반복문을 실행합니다.
for (item in menu) {
  cat(item, '시킬까요?\n')
}

# 반복문 실행 도중 에러가 발생하면 반복문이 중단됩니다.
for (i in 1:5) {
  if (i %% 3 == 0) {
    i <- as.character(x = i)
  }
  print(x = i^2)
}

# 반복문이 중간에 중단되지 않도록 tryCatch() 함수를 추가합니다.
for (i in 1:5) {
  if (i %% 3 == 0) {
    i <- as.character(x = i)
  }
  tryCatch(expr = print(x = i^2),
           error = function(e) cat('에러 발생!\n'))
}


# 숫자형 벡터를 생성하고, while 반복문을 실행합니다.
i <- 5
while (i > 0) {
  print(x = i)
  i <- i - 1
}


# 체질량지수를 반환하는 사용자 정의 함수를 생성합니다.
BMI <- function(height, weight) {
  height <- height / 100
  bmi <- weight / height^2
  return(bmi)
}

BMI(175, 65)
BMI(weight = 65, height = 175)

# 인자의 기본값 설정
BMI <- function(height = 175, weight = 65) {
  height <- height / 100
  bmi <- weight / height^2
  return(bmi)
}

BMI()


## End of Document
