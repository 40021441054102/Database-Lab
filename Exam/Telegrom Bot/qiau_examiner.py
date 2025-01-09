# - Import Necessary Libraries
from telegram.ext import Application, CommandHandler, MessageHandler, filters, CallbackContext
from telegram.constants import ParseMode
from datetime import datetime
from telegram import Update
import asyncio
import random
import json
import os

# - Admin Chats
admin_chat_ids = [
    "715615079",
    "5923170518"
]

# - Define Maximum Link Usage
MAX_LINK_USAGE = 2

# - Define Exams
exams = [
    {
        "name": "امتحان آز پایگاه داده",
        "description": "تایم ۱۳ - رسول صحرایی",
        "pre_time": datetime.strptime("12:45", "%H:%M").time(),
        "start_time": datetime.strptime("13:00", "%H:%M").time(),
        "end_time": datetime.strptime("13:15", "%H:%M").time(),
        "exam_duration": datetime.strptime("0:15", "%H:%M").time().minute,
        "export_file": "time13.json"
    },
    {
        "name": "امتحان آز پایگاه داده",
        "description": "تایم ۱۵ - رسول صحرایی",
        "pre_time": datetime.strptime("14:45", "%H:%M").time(),
        "start_time": datetime.strptime("15:00", "%H:%M").time(),
        "end_time": datetime.strptime("15:15", "%H:%M").time(),
        "exam_duration": datetime.strptime("0:15", "%H:%M").time().minute,
        "export_file": "time15.json"
    },
    {
        "name": "امتحان آز پایگاه داده",
        "description": "تایم ۱۷ - رسول صحرایی",
        "pre_time": datetime.strptime("16:45", "%H:%M").time(),
        "start_time": datetime.strptime("17:00", "%H:%M").time(),
        "end_time": datetime.strptime("17:15", "%H:%M").time(),
        "exam_duration": datetime.strptime("0:15", "%H:%M").time().minute,
        "export_file": "time17.json"
    },
    {
        "name": "امتحان آز پایگاه داده",
        "description": "تایم ۱۹ - رسول صحرایی",
        "pre_time": datetime.strptime("18:45", "%H:%M").time(),
        "start_time": datetime.strptime("19:00", "%H:%M").time(),
        "end_time": datetime.strptime("19:15", "%H:%M").time(),
        "exam_duration": datetime.strptime("0:15", "%H:%M").time().minute,
        "export_file": "time19.json"
    }
]

# - Define Music Links
music_links = [
    {
        "name": "نوش آفرین",
        "url": "https://xx.sahand-music.ir/Archive/N/Nooshafarin/Nooshafarin%20-%20Attash/04%20Ashti.mp3"
    },
    {
        "name": "معین",
        "url": "https://dl.mehrdl.top/Music/A/F/Moein-paricheh/06%20Paricheh.mp3"
    },
    {
        "name": "آرش",
        "url": "https://www.tarafdari.com/sites/default/files/contents/user871280/content-sound/arash_-_broken_angel_320.mp3"
    },
    {
        "name": "The Boyz",
        "url": "https://dl5.download1music.ir/Music/2023/The%20Boyz/The%20Boyz%20-%20Bigharar.mp3"
    },
    {
        "name": "مهرشاد",
        "url": "https://sv.jenabmusic.com/music/2024/06/15/mehrshad_baba_to%20dige%20ki%20hasti.mp3"
    },
    {
        "name": "مهرشاد",
        "url": "https://dl.nicmusic.net/nicmusic/030/011/Mehrshad%20-%20Bahare.mp3"
    }
]

# - Define Exam Links with Their Usages
exam_links = {
    "https://forms.gle/Y64AZkaLVYsT4CeGA": 0,
    "https://forms.gle/xi3yiJimteyntZqi9": 0,
    "https://forms.gle/y7yRszkpYLXhi7hQA": 0,
    "https://forms.gle/FjcyLeDEACSx3v4dA": 0,
    "https://forms.gle/R7GnLJEAKRfmWLNG8": 0,
    "https://forms.gle/BHUsDfPLW3Vvxiqi6": 0,
    "https://forms.gle/RwkVr6XCEPFyURbW9": 0,
    "https://forms.gle/sGDLy1TyahbcZtkb7": 0
}

# - Define Student Links
students_links = {}

# - Method to Handle the /start Command
async def start(
    update: Update,
    context: CallbackContext
) -> None:
    # - Check if User Chat ID is within Admin Chat IDs
    for admin_chat_id in admin_chat_ids:
        if update.message.chat_id == int(admin_chat_id):
            print("Admin is trying to start the exam")
            # - Calculate Howmany Users are in the Exam
            count = 0
            for exam in exams:
                try:
                    # - Count the Number of Students in the Exam Export File
                    with open(exam["export_file"], "r") as file:
                        students = json.load(file)
                        count += len(students)
                except Exception as e:
                    print(f"Error: {e}")
            # - Send Message to User
            await update.message.reply_text(f'ادمین محترم {exam["name"]} شروع شده و در حال حاظر {count} نفر امتحان می‌دهند.')
            return
    # - say user's name
    await update.message.reply_text(f'سلام {update.message.from_user.first_name} خوبی ؟\nبذار چک کنم ببینم استادی هستش که برای آیدی تو آزمون تعیین کرده باشه ...')
    await asyncio.sleep(0.7)
    # - Check Exam Time
    current_exam = None
    for exam in exams:
        # - Set Current Time
        current_time = datetime.now().time()
        # - Check if Exam is in Preparation
        if exam["pre_time"] < current_time < exam["start_time"]:
            current_exam = exam
            message_pre = await update.message.reply_text(f'اینطور که پیداست {exam["name"]} داری ({exam["description"]}).\nساعت شروع امتحان {exam["start_time"]} هستش که تا اون زمان باید منتظر بمونی بعد دوباره من رو استارت کنی. مدت آزمون هم {exam["exam_duration"]} دقیقه هستش.')
            # - Calculate Remaining Time
            remaining_time = datetime.combine(datetime.now().date(), exam["start_time"]) - datetime.combine(datetime.now().date(), current_time)
            # - Select Random Music Link
            music_link = random.choice(music_links)
            # - Send Music Link to User
            message_music = await update.message.reply_text(f'تا منتظر میمونی این آهنگ از {music_link["name"]} رو گوش کن :')
            await update.message.reply_audio(audio = music_link["url"], reply_to_message_id = message_music.message_id)
            # - Check if Remaining Time is Less than 1 Minute
            if remaining_time.seconds < 60:
                await update.message.reply_text(f'زمان باقی مانده تا شروع امتحان : {remaining_time.seconds} ثانیه', reply_to_message_id = message_pre.message_id)
            else:
                await update.message.reply_text(f'زمان باقی مانده تا شروع امتحان : {remaining_time.seconds // 60} دقیقه و {remaining_time.seconds % 60} ثانیه', reply_to_message_id = message_pre.message_id)
            # - Alert Admins
            for admin_chat_id in admin_chat_ids:
                await context.bot.send_message(chat_id = admin_chat_id, text = f"آیدی {update.message.from_user.first_name} وارد ربات شد ولی آزمون هنوز شروع نشده")
            print("Exam for the user {} is in preparation".format(update.message.from_user.first_name))
            break
        # - Check if Exam is in Progress
        if current_time >= exam["start_time"] and current_time <= exam["end_time"]:
            # - Check if User has Already Received a Link
            if update.message.from_user.id in students_links.keys():
                # - Alert User that Link has Already Been Sent
                message_exam = await update.message.reply_text('آزمون شروع شده ولی قبلا بهت لینک دادم :')
                current_exam = exam
                url = students_links[update.message.from_user.id]["link"]
                # - Show the Link to the User
                await update.message.reply_text(url, reply_to_message_id = message_exam.message_id)
            else:
                message_exam = await update.message.reply_text(f'{exam["name"]} شروع شده وارد لینک زیر بشو :')
                current_exam = exam
                print("Exam for the user {} is in progress".format(update.message.from_user.first_name))
                # - Select a Link if It is Not Used More than MAX_LINK_USAGE
                url = ""
                # - select a link if it is not used more than MAX_LINK_USAGE
                for link in exam_links:
                    # - Check if User ID is within Specific IDs
                    if exam_links[link] < MAX_LINK_USAGE:
                        # - Set URL
                        url = link
                        # - Increment Link Usage
                        exam_links[link] += 1
                        break
                # - If No Link is Available, Select a Random Link
                if url == "":
                    url = random.choice(list(exam_links.keys()))
                    print("No link available, random link selected for the user {}".format(update.message.from_user.first_name))
                # - Show All Links and Their Usage
                print("--------------------")
                print("Links:")
                for link in exam_links:
                    print(f"{link}: {exam_links[link]}")
                print("--------------------")
                # - Send the Link to the User
                message_exam_url = await update.message.reply_text(url, reply_to_message_id = message_exam.message_id)
                # - Define New Student Exam Object
                exam_object = {
                    "link": url,
                    "name": update.message.from_user.first_name,
                    "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                    "chat_id": update.message.chat_id,
                    "message_id": message_exam_url.message_id
                }
                # - Add the Link to the List of Links of the User
                students_links[update.message.from_user.id] = exam_object
                # - Send Exam Object to Admins
                for admin_chat_id in admin_chat_ids:
                    formatted_json = json.dumps(exam_object, indent=4)
                    escaped_json = formatted_json.replace('.', '\\.').replace('-', '\\-').replace('{', '\\{').replace('}', '\\}').replace('[', '\\[').replace(']', '\\]').replace('(', '\\(').replace(')', '\\)').replace('#', '\\#').replace('+', '\\+').replace('!', '\\!').replace('=', '\\=')
                    await context.bot.send_message(
                        chat_id = admin_chat_id,
                        text = f"آیدی {update.message.from_user.first_name} وارد آزمون شد\n```\n{escaped_json}\n```",
                        parse_mode = ParseMode.MARKDOWN_V2
                    )
                # - Load JSON File as Append Mode
                with open(exam["export_file"], "w") as file:
                    # - Save the List of Links of the User to a JSON File
                    json.dump(students_links, file, indent = 4)
                break
    if current_exam is None:
        await update.message.reply_text("در حال حاضر هیچ استادی برای تو آزمونی تعریف نکرده.")
        print("No exam is defined for the user {}".format(update.message.from_user.first_name))
        return

# - Method to Handle Incoming Messages
async def echo(update: Update, context: CallbackContext) -> None:
    await update.message.reply_text(update.message.text)

# - Main Function to Start the Bot
def main():
    # - Create a new Application Instance
    application = Application.builder().token(os.getenv("QIAU_EXAMINER_TELBOT_KEY")).build()
    # - Add Command Handler for /start
    application.add_handler(CommandHandler("start", start))
    # - Add Message Handler for Echo
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, echo))
    # - Start the Bot in Polling Mode
    application.run_polling()

if __name__ == '__main__':
    main()
