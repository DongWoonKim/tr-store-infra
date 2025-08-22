# 📖 프로젝트 설명
**TR-STORE**는 온라인 도서 판매를 위한 MSA(Microservices Architecture) 기반 서비스입니다.  
사용자는 회원 가입/로그인을 통해 웹 애플리케이션을 통해 도서를 검색하고, 상세 정보를 조회하는 기능을 이용할 수 있습니다.  

# 🏗 TR-STORE 서비스 구성

TR-STORE는 크게 다섯 개의 독립적인 서비스로 구성되어 있습니다.

- **사용자 화면 서비스 (Front)** : [tr-web-service](https://github.com/DongWoonKim/tr-web-service)  
- **백엔드 서비스들의 단일 진입점 (Gateway)** : [tr-edge-service](https://github.com/DongWoonKim/tr-edge-service)  
- **인증 서비스 (Auth)** : [tr-auth-service](https://github.com/DongWoonKim/tr-auth-service)  
- **도서 정보 제공 서비스 (Catalog)** : [tr-catalog-service](https://github.com/DongWoonKim/tr-catalog-service)  
- **도서 검색 서비스 (Search)** : [tr-search-service](https://github.com/DongWoonKim/tr-search-service)  

---

# 📦 도메인 모델 설명
각 서비스의 상세 도메인 모델은 해당 리포지토리의 README를 참고하세요.  
여기서는 구현 과정에서 반복적으로 점검했던 **세 가지 핵심 설계 포인트**만 간략히 정리합니다.  

### 1. Bounded Context

요구사항을 분석하는 과정에서 **도메인 모델이 적용되는 유효 범위(경계)**에 대한 고민이 컸습니다.  
특히 **도서 정보(Catalog)**와 **검색(Search)**를 하나의 모델로 처리할 수 없었고,  
서로 다른 책임과 언어를 가진다는 점에서 분리가 필요했습니다.

- **Catalog 컨텍스트**
  - 진실의 원천(Source of Truth) 역할
  - ISBN, 제목/부제, 저자, 출판사, 발행일, 표지 URL 등 도서의 핵심 속성을 관리  

- **Search 컨텍스트**
  - 조회 및 탐색 최적화에 초점
  - 질의, 랭킹, 하이라이트, 논리 연산자(OR/NOT), 페이지네이션 등 검색 기능 중심으로 모델 정의  

결과적으로 같은 “도서”라는 개념이라도,  
**Catalog에서는 데이터 정합성 유지와 관리가 핵심**이고,  
**Search에서는 빠르고 다양한 검색 경험 제공이 핵심**이므로  
두 컨텍스트를 분리하는 것이 타당하다고 판단했습니다.

---

### 2. 비즈니스 로직은 순수 도메인에 의존해야 한다

엔티티와는 별개로 도메인 모델을 정의하고, 서비스 계층이 이 도메인 모델만을 사용하도록 설계하면  
비즈니스 로직을 영속성 계층으로부터 완전히 분리할 수 있습니다.  

이 과정에서 흔히 **어댑터(Adapter)** 라고 부르는 요소가 중요한 역할을 합니다.  
어댑터는 도메인 모델과 영속성 계층을 연결해 주는 다리 역할을 하며,  
이를 통해 **비즈니스 계층과 데이터 접근 계층의 관심사 분리**를 온전히 달성할 수 있습니다.

---

### 3. 도메인 침범은 하지 않는다 (DB 관점)

각 도메인은 **자신의 데이터베이스에만 접근**해야 하며,  
다른 도메인의 DB 스키마를 직접 조회하거나 수정해서는 안 됩니다.  

- **자신의 컨텍스트만 관리**  
  Catalog 도메인은 Catalog DB만, Search 도메인은 Search 인덱스/저장소만 다룬다.  

- **교류는 반드시 도메인 API를 통해서**  
  다른 도메인의 데이터가 필요하다면 해당 도메인의 **도메인 서비스나 API**를 호출해서 가져온다.  
  DB 스키마를 직접 건드리면 결합도가 높아지고, 도메인 독립성이 깨진다.

---

# 📑 TR-STORE API 문서(Swagger) 안내

> 각 서비스는 Springdoc(OpenAPI) 기반 Swagger UI를 제공합니다.   

- **Auth 서비스 (tr-auth-service, :9001)**  
  - [Swagger UI](http://localhost:9001/swagger-ui/index.html)  
  - [OpenAPI Docs (JSON)](http://localhost:9001/v3/api-docs)

- **Catalog 서비스 (tr-catalog-service, :9002)**  
  - [Swagger UI](http://localhost:9002/swagger-ui/index.html)  
  - [OpenAPI Docs (JSON)](http://localhost:9002/v3/api-docs)

- **Search 서비스 (tr-search-service, :9003)**  
  - [Swagger UI](http://localhost:9003/swagger-ui/index.html)  
  - [OpenAPI Docs (JSON)](http://localhost:9003/v3/api-docs)

---

# 🚀 실행방법

> **⚠️ 사전작업**  
> - 🐳Docker 설치는 필수로 해주셔야 합니다.

**5개의 서비스와 인프라를 모두 clone하여 아래와 같은 구조로 만들어주세요.**
```bash
trevari/
├─ tr-web-service/                [tr-web-service](https://github.com/DongWoonKim/tr-web-service) 
├─ tr-edge-service/               [tr-edge-service](https://github.com/DongWoonKim/tr-edge-service) 
├─ tr-auth-service/               [tr-auth-service](https://github.com/DongWoonKim/tr-auth-service)  
├─ tr-catalog-service/            [tr-catalog-service](https://github.com/DongWoonKim/tr-catalog-service)  
├─ tr-search-service/             [tr-search-service](https://github.com/DongWoonKim/tr-search-service)  
└─ docker/                        [tr-store-infra](https://github.com/DongWoonKim/tr-store-infra)
   ├─ docker-compose.data.yml    
   ├─ docker-compose.service.yml 
   ├─ docker-compose.front.yml   
   ├─ start.sh                   
   └─ db/
      └─ init.sql                

# docker 디렉토리로 이동
cd trevari/docker

# 실행 스크립트 권한 부여
chmod +x start.sh

# 실행
./start.sh

# 회원가입 후, 로그인해 주세요.
http://localhost:8001/auth/login
```

# 🗺️ 아키텍처 및 기술 스택 선택 배경

## 1. MSA 도입 여부

### MSA 아키텍처 채택 이유
1) **장애 격리성 확보**  
   도메인 모델링 과정에서 특정 도메인에 장애가 발생하더라도 다른 도메인으로 전파되지 않도록 하기 위해 MSA를 도입하였습니다.  
   과제 제출 시 정상 동작하는 서비스를 반드시 제출해야 하는 상황에서, 모놀리식 구조를 선택할 경우 단일 장애가 전체 서비스 중단으로 이어져 평가 자체가 불가능해질 위험이 있습니다.  
   반면 MSA 구조를 적용하면, 하나의 서비스에 문제가 발생하더라도 나머지 서비스는 정상적으로 동작할 수 있어 **부분적인 평가라도 받을 수 있는 안정성**을 확보할 수 있습니다.

2) **부가 기능 확장성 (Rate Limiting, 모니터링 등)**  
   여력이 된다면 Rate Limiting이나 모니터링 같은 기능들을 고려했을 때, 분산 환경이 더 유리하다고 판단했습니다.  
   모놀리식 구조에서도 어느 정도 가능하지만, 서비스 경계가 뚜렷한 분산 환경에서는 이러한 기능을 더 세밀하게 적용하고 확장하기 용이합니다.  
   특히 서비스별로 장애 지점을 빠르게 추적해야 하는 상황에서, 분산 아키텍처가 제공하는 **격리성(Isolation)** 은 큰 장점이 될 수 있습니다.  

   물론 처음 마음만큼 일정이 쉽지는 않았습니다 😅

---

## 2. API Gateway

**Spring Cloud Gateway**를 사용하여 인증·인가, 로깅, 라우팅을 중앙에서 처리하도록 구성했습니다.  
이를 통해 각 서비스마다 개별적으로 구현해야 할 공통 기능을 게이트웨이에서 일괄적으로 관리할 수 있었고, 서비스 간 호출 구조 역시 단순화되어 **프론트 구현 시 전체 시스템의 복잡성을 줄이는 효과**를 얻을 수 있었습니다.

---

## 3. 인증 방식

인증 방식으로는 **JWT(Json Web Token)** 기반 방식을 채택했습니다.  
세션을 서버에 저장하지 않고 토큰 자체에 인증 정보를 포함시킴으로써 **Stateless 아키텍처**를 유지할 수 있었으며, 서비스 확장성과 분산 환경에 적합한 구조를 갖출 수 있었습니다.  

또한 서버가 별도의 세션 상태를 관리하지 않아도 되기 때문에, 서버의 부담을 줄이고 요청 처리 성능을 높이는 효과도 있었습니다.

---

## 4. 데이터 저장소 선택

처음에는 검색 기능을 고려하여 **PostgreSQL의 Full-Text Search(FTS)** 기능을 활용하기 위해 PostgreSQL을 선택했습니다.  
저장되는 데이터가 정형 데이터이므로 굳이 NoSQL을 선택할 필요가 없다고 판단했습니다.  
또 Databaser같은 경우 한번 선택하면 변경이 쉽지 않기에 여러 확장성과 PostgreSQL이 갖는 특징 등을 고려했을 때 적합하다 판단하여 그대로 유지합니다.

하지만 초기 모놀리식 아키텍처를 폐기하고 다시 설계하는 과정에서, 전문 검색 엔진을 도입하기로 결정했습니다.  
그 과정에서 **OpenSearch**와 **Elasticsearch**를 모두 검토했으나, 최종적으로 Elasticsearch를 선택했습니다.

### Elasticsearch 선택 이유
- **풍부한 생태계와 문서화**  
  OpenSearch는 AWS 주도로 발전하고 있지만, 자료나 커뮤니티 규모 측면에서는 여전히 Elasticsearch가 더 풍부합니다.
- **안정성과 검증된 사용 사례**  
  Elasticsearch는 다양한 서비스에서 이미 안정적으로 활용되고 있어 학습 비용을 줄이고 시행착오를 최소화할 수 있습니다.
- **기술 스택 적합성**  
  회사의 기존 기술 스택에 Elasticsearch가 포함되어 있어, 이번 프로젝트에서도 활용함으로써 실무 경험을 쌓는 데 유리하다고 판단했습니다.

> **FTS(Full-Text Search)** : 데이터베이스 안에 저장된 텍스트(문서, 문장, 단어)를 단순히 `LIKE '%키워드%'` 같은 문자열 검색이 아닌, **자연어 기반으로 효율적이고 정확하게 검색할 수 있도록 해주는 기능**

---

## 5. 프론트엔드 프레임워크 (Thymeleaf + jQuery)

프론트엔드는 **Thymeleaf**와 **jQuery**를 선택했습니다.  
이번 과제에서는 복잡한 화면 구현보다는 **간단한 UI 요구사항**이 중심이었기 때문에, 별도의 SPA 프레임워크(React, Vue 등)를 도입할 필요는 없다고 판단했습니다.  

또한 새로운 프레임워크를 학습하는 데 시간을 투자하기보다는, 제가 가장 빠르게 속도를 낼 수 있는 기술 조합을 선택하여 **학습 곡선을 최소화**하고, 구현 속도를 높이는 데 집중했습니다.

# 📌 아키텍처 결정 사항 및 고민 과정  

---

### 1. 아키텍처 선택 (모놀리식 vs MSA)  
- **고민**  
  - 모놀리식은 구현 속도가 빠르지만, 하나의 장애가 전체 서비스에 영향을 미칠 수 있음.  
  - MSA는 서비스 간 격리성이 보장되어 안정성은 높지만, 초기 구현 복잡도가 커서 일정 관리에 부담이 됨.  

- **결론**  
  - 부분 실패에도 평가가 가능하도록 **MSA를 선택**.  

---

### 2. 검색 기능 구현 (DB FTS vs 검색엔진)  
- **고민**  
  - PostgreSQL의 FTS를 활용하면 초기에는 빠르게 구현 가능.  
  - 그러나 서비스가 확장될수록 고급 검색 기능(자동완성, 유사도 검색, 가중치 설정 등)이 필요할 가능성이 높음.  

- **접근**  
  - OpenSearch vs Elasticsearch를 비교.  
  - 커뮤니티 규모, 생태계, 안정성 측면에서 **Elasticsearch를 최종 선택**.  

---

### 3. 인증/인가 (JWT)  
- **고민 1**  
  - 단순히 과제 제출용이라면 회원가입 절차를 생략하고 Access Token도 하드코딩할 수 있었음.  
  - 그러나 최소한의 정상적인 인증·인가 흐름 구현이 의미 있다고 판단하여, 회원가입·로그인 과정을 포함한 JWT 기반 인증을 적용.  

- **고민 2**  
  - Refresh Token 관리 방식을 고려해야 했음.  
  - Redis + TTL 방식이 이상적이지만, 용량 관리 및 추가 고려 포인트들이 일정상 부담이 됨.  
  - 따라서 이번 과제에서는 **쿠키 & 로컬스토리지 방식을 선택**.  

---

### 4. 도메인 모델링  
- **고민**  
  - 도메인 모델이 프레임워크나 외부 기술에 의존하지 않고 순수한 상태를 유지하려면 어떻게 해야 할까?  

- **접근**  
  - 비즈니스 로직은 엔티티와 도메인 서비스에 두고, 데이터 접근/외부 API 연동은 인프라 계층으로 분리.  
  - 도메인 계층에서는 인터페이스(포트)를 정의하고, 실제 구현체(어댑터)는 인프라 계층에 배치.  

- **효과**  
  - 도메인 로직이 특정 기술 스택(JPA, Spring 등)에 덜 묶임.  
  - 유지보수성과 테스트 용이성이 향상됨.  
  - 비즈니스 규칙을 코드 중심에 두는 설계를 유지할 수 있었음.
  - 단위 테스트 코드 작성에 유리했음.



  
