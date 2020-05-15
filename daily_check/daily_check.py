#    Code    :  UTF-8
#    Time    :  2020/5/7 15:55
#    Name    :  daily_check.py
#    Env     :  PyCharm
#    By Gopppog

import os
import time
import datetime
import logging
import smtplib
import argparse
import json
import ssl
from pathlib import Path
from email.mime.text import MIMEText
from email.header import Header
from telnetlib import Telnet
from urllib import request, error

def pingcheck(ip):
    cmd = "ping " + ip + " -c 1 -W 1 >/dev/null 2>&1"
    if os.system(cmd) == 0:
        return True
    else:
        return False

def urlcheck(url):
    available_time = 0
    for n in range(3):
        try:
            with request.urlopen(url, timeout=2) as resp:
                if resp.code == 200:
                    available_time += 1
                time.sleep(0.5)
        except error.URLError:
            pass
        except error.HTTPError:
            pass
        except:
            pass
    if available_time == 0:
        return False
    else:
        return True

def portcheck(Host, Port):
    try:
        tn = Telnet(Host, port=Port, timeout=2)
        tn.close()
        return True
    except:
        return False

def mail(mesg, rec, auth):
    subject = "%s 巡检故障报警" % (datetime.date.today())
    message = MIMEText(mesg, "plain", "utf-8")
    message["To"] = Header(rec)
    message["Subject"] = Header(subject, "utf-8")
    try:
        smtpObj = smtplib.SMTP()
        smtpObj.connect(auth["mail_host"], 25)
        smtpObj.login(auth["mail_user"], auth["mail_pass"])
        smtpObj.sendmail(auth["mail_sender"], rec, message.as_string())
        return True
    except:
        return False

if __name__ == '__main__':
    ssl._create_default_https_context = ssl._create_unverified_context
    parse = argparse.ArgumentParser()
    parse.add_argument("-c", "--config", help="specify JSON file of normal configuration absolute path ")
    parse.add_argument("-i", "--item", help="specify JSON file of services configuration absolute path")
    parse.add_argument("-s", "--silence", action="store_true", help="Dump output on /var/log/daily_check ")
    parse.add_argument("-v", "--version", action="store_true", help="show version information")
    args = parse.parse_args()
    if args.item:
        if Path(args.item).exists():
            with open(Path(args.item), "r", encoding="utf-8") as i:
                service = json.load(i)
                print("巡检服务配置文件导入成功：%s" %(Path(args.item)))
        else:
            service = None
            print("巡检服务配置文件不存在：%s" %(Path(args.item)))
            exit(1)
    else:
        if Path(os.path.join(os.path.dirname(__file__), "service.json")).exists():
            with open(Path(os.path.join(os.path.dirname(__file__), "service.json")), "r", encoding="utf-8") as i:
                service = json.load(i)
                print("巡检服务配置文件导入成功：%s" %(Path(os.path.join(os.path.dirname(__file__), "service.json"))))
        else:
            service = None
            print("巡检配置文件不存在：%s" %(Path(os.path.join(os.path.dirname(__file__), "service.json"))))
            exit(1)
    if args.config:
        if Path(args.config).exists():
            with open(Path(args.config), "r", encoding="utf-8") as f:
                config = json.load(f)
                print("配置文件导入成功： %s" %(Path(args.config)))
        else:
            config = None
            exit(1)
            print("配置文件不存在：%s" %(Path(args.config)))
    else:
        if Path(os.path.join(os.path.dirname(__file__), "config.json")).exists():
            with open(Path(os.path.join(os.path.dirname(__file__), "config.json")), "r", encoding="utf-8") as f:
                config = json.load(f)
                print("配置文件导入成功：%s" %(Path(os.path.join(os.path.dirname(__file__), "config.json"))))
        else:
            config = None
            print("配置文件不存在：%s" %(Path(os.path.join(os.path.dirname(__file__), "config.json"))))
    if args.version:
        if config:
            print("Daily Check Script by Gopppog\n Version %s"%(config["version"]))
            exit(0)
        else:
            print("Can't load configration file . Unknow Version information")
            exit(0)
    if args.silence:
        print("进入沉默模式")
        log_path = "/var/log/daily_check"
        log_format = "%(message)s"
        logging.basicConfig(filename=log_path, level=logging.DEBUG, format=log_format)
        logger = logging.getLogger()
        logger.info("\n\n\n\n\n\n\n\n\n")
        logger.info("xxxxxx[巡检开始]xxxxxx - 当前时间 {:%Y-%m-%d %H:%M:%S}".format(datetime.datetime.today()))
        t0 = time.time()
        failed_count = 0
        success_count = 0
        for name in service["SERVICES"]:
            if service["SERVICES"][name]["check_mthod"] == "urlcheck":
                res = urlcheck(service["SERVICES"][name]["input"]["url"])
                if res:
                    log = name + " Checked -- > [服务正常]"
                    logger.info(log)
                    success_count += 1
                else:
                    failed_count += 1
                    if config:
                        log = name + " Checked -- > [服务故障]" + " ++邮件报警开始++"
                        logger.info(log)
                        for rec in config["receive_mail"]:
                            mess = str(name + "故障，请及时处理")
                            send_sts = mail(mess, rec, config["auth_mail_setting"])
                            if send_sts:
                                log = "发送报警邮件 To" + rec + " 成功"
                                logger.info(log)
                            else:
                                log = "发送报警邮件 To" + rec + " 失败"
                                logger.info(log)
                    else:
                        log = name + " Checked -- > [服务故障]" + " ++邮件报警忽略++"
                        logger.info(log)
            if service["SERVICES"][name]["check_mthod"] == "pingcheck":
                for IP in service["SERVICES"][name]["input"]:
                    res = pingcheck(IP)
                    if res:
                        log = name + " Checked %s -- > [服务正常]"%(IP)
                        logger.info(log)
                        success_count += 1
                    else:
                        failed_count += 1
                        if config:
                            log = name + " Checked %s -- > [服务故障]"%(IP) + " ++邮件报警开始++"
                            logger.info(log)
                            for rec in config["receive_mail"]:
                                mess = str(name + "%s 故障，请及时处理"%(IP))
                                send_sts = mail(mess, rec, config["auth_mail_setting"])
                                if send_sts:
                                    log = "发送报警邮件 To" + rec + " 成功"
                                    logger.info(log)
                                    time.sleep(10)
                                else:
                                    log = "发送报警邮件 To" + rec + " 失败"
                                    logger.info(log)
                        else:
                            log = name + " Checked %s -- > [服务故障]" %(IP) + " ++邮件报警忽略++"
                            logger.info(log)
            if service["SERVICES"][name]["check_mthod"] == "portcheck":
                res = portcheck(service["SERVICES"][name]["input"]["host"], service["SERVICES"][name]["input"]["port"])
                if res:
                    log = name + " Checked -- > [服务正常]"
                    logger.info(log)
                    success_count += 1
                else:
                    failed_count += 1
                    if config:
                        log = name + " Checked -- > [服务故障]" + " ++邮件报警开始++"
                        logger.info(log)
                        for rec in config["receive_mail"]:
                            mess = str(name + "故障，请及时处理")
                            send_sts = mail(mess, rec, config["auth_mail_setting"])
                            if send_sts:
                                log = "发送报警邮件 To" + rec + " 成功"
                                logger.info(log)
                            else:
                                log = "发送报警邮件 To" + rec + " 失败"
                                logger.info(log)
                    else:
                        log = name + " Checked -- > [服务故障]" + " ++邮件报警忽略++"
                        logger.info(log)
        t1 = time.time()
        delta_second = int(t1 - t0)
        total_check_count = success_count + failed_count
        healthy_rates = "%.2f%%" % (success_count / total_check_count * 100)
        log = "巡检总耗时： %s 秒"%(delta_second) + " 总检查服务数：%s"%(total_check_count) + " 故障服务数：%s"%(failed_count) + " 巡检服务健康率：%s"%(healthy_rates)
        logger.info(log)
        logger.info("xxxxxx[巡检结束]xxxxxx - 当前时间 {:%Y-%m-%d %H:%M:%S}".format(datetime.datetime.today()))
    else:
        print("当前处于非沉默模式")
        print("xxxxxx[巡检开始]xxxxxx - 当前时间 {:%Y-%m-%d %H:%M:%S}".format(datetime.datetime.today()))
        t0 = time.time()
        failed_count = 0
        success_count = 0
        for name in service["SERVICES"]:
            if service["SERVICES"][name]["check_mthod"] == "urlcheck":
                res = urlcheck(service["SERVICES"][name]["input"]["url"])
                if res:
                    print(name, " Checked -- > \033[1;32;47m[服务正常]\033[0m")
                    success_count += 1
                else:
                    failed_count += 1
                    if config:
                        print(name, " Checked -- > \033[5;31;47m[服务故障]\033[0m" + " ++邮件报警开始++")
                        for rec in config["receive_mail"]:
                            mess = str(name + "故障，请及时处理")
                            send_sts = mail(mess, rec, config["auth_mail_setting"])
                            if send_sts:
                                print("发送报警邮件 To", rec, " \033[1;32;47m成功\033[0m")
                            else:
                                print("发送报警邮件 To", rec, " \033[5;31;47m失败\033[0m")
                    else:
                        print(name, " Checked -- > \033[5;31;47m[服务故障]\033[0m" + " ++邮件报警忽略++")
            if service["SERVICES"][name]["check_mthod"] == "pingcheck":
                for IP in service["SERVICES"][name]["input"]:
                    res = pingcheck(IP)
                    if res:
                        print(name, " Checked %s -- > \033[1;32;47m[服务正常]\033[0m"%(IP))
                        success_count += 1
                    else:
                        failed_count += 1
                        if config:
                            print(name, " Checked %s -- > \033[5;31;47m[服务故障]\033[0m"%(IP), " ++邮件报警开始++")
                            for rec in config["receive_mail"]:
                                mess = str(name + "%s 故障，请及时处理"%(IP))
                                send_sts = mail(mess, rec, config["auth_mail_setting"])
                                if send_sts:
                                    print("发送报警邮件 To", rec, " \033[1;32;47m成功\033[0m")
                                    time.sleep(10)
                                else:
                                    print("发送报警邮件 To", rec, " \033[5;31;47m失败\033[0m")
                        else:
                            print(name, " Checked %s -- > \033[5;31;47m[服务故障]\033[0m" % (IP), " ++邮件报警忽略++")
            if service["SERVICES"][name]["check_mthod"] == "portcheck":
                res = portcheck(service["SERVICES"][name]["input"]["host"], service["SERVICES"][name]["input"]["port"])
                if res:
                    print(name, " Checked -- > \033[1;32;47m[服务正常]\033[0m")
                    success_count += 1
                else:
                    failed_count += 1
                    if config:
                        print(name, " Checked -- > \033[5;31;47m[服务故障]\033[0m" + " ++邮件报警开始++")
                        for rec in config["receive_mail"]:
                            mess = str(name + "故障，请及时处理")
                            send_sts = mail(mess, rec, config["auth_mail_setting"])
                            if send_sts:
                                print("发送报警邮件 To", rec, " \033[1;32;47m成功\033[0m")
                            else:
                                print("发送报警邮件 To", rec, " \033[5;31;47m失败\033[0m")
                    else:
                        print(name, " Checked -- > \033[5;31;47m[服务故障]\033[0m" + " ++邮件报警忽略++")
        t1 = time.time()
        delta_second = int(t1 - t0)
        total_check_count = success_count + failed_count
        healthy_rates = "%.2f%%" % (success_count / total_check_count * 100)
        print("巡检总耗时： %s 秒" %(delta_second), " 总检查服务数：%s" %(total_check_count),
              " 故障服务数：%s" %(failed_count), " 巡检服务健康率：%s" %(healthy_rates))
        print("xxxxxx[巡检结束]xxxxxx - 当前时间 {:%Y-%m-%d %H:%M:%S}".format(datetime.datetime.today()))







