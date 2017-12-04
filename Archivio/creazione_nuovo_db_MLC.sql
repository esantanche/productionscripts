disk init name = "NOME_DB@NEW#L01", 
          physname = "/syb_db_piccoli_db/NOME_DB@NEW#L01", 
          size = "1000M"
go
disk init name = "NOME_DB@NEW#D01", 
          physname = "/syb_db_piccoli_db/NOME_DB@NEW#D01", 
          size = "2000M"
go
create database NOME_DB@NEW on NOME_DB@NEW#D01 = 2000 log on        
              NOME_DB@NEW#L01 = 1000	  
go

