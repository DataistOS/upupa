Dart SDK راهنمای
=============================================

پکیج `upupa_dart` کلاینت رسمی برای ارتباط با بک‌اند Upupa است. این پکیج مدیریت احراز هویت، توکن‌ها، سرویس‌های Collection و عملیات CRUD روی رکوردها را به ساده‌ترین شکل فراهم می‌کند.

۱. نصب و راه‌اندازی اولیه
-----------------------------

برای اضافه کردن SDK به پروژه فلاتر یا دارت خود، آن را در `pubspec.yaml` اضافه کنید یا به صورت محلی لینک دهید:

.. code-block:: yaml

   dependencies:
     upupa_dart:
       path: ../upupa_dart

مقداردهی اولیه کلاینت (`UpupaClient`) و ذخیره‌گاه توکن:

.. code-block:: dart

   import 'package:upupa_dart/upupa_dart.dart';

   void main() async {
     // ایجاد نمونه کلاینت با آدرس پایه بک‌اند
     final client = UpupaClient(baseUrl: 'http://localhost:8090/api/v1');

     // بررسی وضعیت ورود کاربر
     if (client.authStore.isValid) {
       print('کاربر وارد شده است: \${client.authStore.model}');
     }
   }

۲. احراز هویت (Authentication)
---------------------------------

برای ورود کاربران یا ادمین‌ها به سیستم از طریق `AuthService`:

.. code-block:: dart

   try {
     final authData = await client.collection('users').authWithPassword(
       'admin@example.com',
       'password123',
     );
     print('ورود موفقیت‌آمیز بود! توکن: \${client.authStore.token}');
   } catch (e) {
     print('خطا در احراز هویت: \$e');
   }

۳. کار با رکوردها (Record Service)
-------------------------------------

برای دریافت، ایجاد یا ویرایش رکوردها در مجموعه‌ها (Collections):

.. code-block:: dart

   // دریافت لیست رکوردها با فیلتر و صفحه‌بندی
   final result = await client.collection('posts').getList(
     page: 1,
     perPage: 20,
     filter: "status = 'active'",
     sort: '-created',
   );

   // ایجاد رکورد جدید
   final record = await client.collection('posts').create(body: {
     'title': 'مستندات جدید Upupa',
     'status': 'active',
   });