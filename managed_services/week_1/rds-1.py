# *********************************************************************************************************************
# Author - Nirmallya Mukherjee
# This script will connect to a MySQL DB using multiple driver options
# *********************************************************************************************************************
import pymysql
import mysql.connector

hostname = "mydb.123456789012.us-east-1.rds.amazonaws.com"
# hostname = 'localhost'
username = "root"
password = "password"
database = "employees"


# Simple routine to run a query on a database and print the results:
def doQuery(conn):
    cur = conn.cursor()
    cur.execute("SELECT employee_id, employee_name FROM employees limit 10")
    for emp_name in cur.fetchall():
        print(emp_name)


def pymysqlConnector():
    print("Using pymysql")
    print("-------------")
    myConnection = pymysql.connect(
        host=hostname, user=username, passwd=password, db=database
    )
    doQuery(myConnection)
    myConnection.close()


def mysqlConnector():
    print("\n\nUsing mysql.connector")
    print("---------------------")
    myConnection = mysql.connector.connect(
        host=hostname, user=username, passwd=password, db=database
    )
    doQuery(myConnection)
    myConnection.close()


def createOrder():
    print(
        "\n\nUsing any of the above connectors, insert a new record in the orders table"
    )
    conn = mysql.connector.connect(
        host=hostname, user=username, passwd=password, db=database
    )
    cur = conn.cursor()
    # TBD:You have to write this code and submit as part of the lab

    conn.commit()
    cur.close()
    conn.close()


def main():
    pymysqlConnector()
    mysqlConnector()
    createOrder()


main()
