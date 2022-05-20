# Projeto BD

## Manual de Instalacao

### Requerimentos
1. PostgreSQL
2. Python 3.9
3. Libraries & Frameworks
### Bibliotecas auxiliares
- `JWT` pip install PyJWT
- `Flask` pip install Flask
- `Psycog2` pip install psycopg2

<br/>



## Manual de utilizacao 

### Connect to database
```shell
psql -h localhost -p 5432 -d postgres -U postgres
```
### Create User
``` shell
create user aulaspl with encrypted password 'aulaspl'
```
### Create Database
``` shell
create database projetobd
```
### Give Privileges to user
``` shell
grant all privileges on database projetobd to aulaspl
```
### Run API
Run *loja.py* on your prefered IDE or Text Editor
### Reach Endpoints
Use Postman or other equivalent software to interact with the API
<br/>

## Devs
Eduardo Figueiredo<br/>
Fábio Santos
