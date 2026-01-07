import 'dart:convert';

/// msg : "操作成功"
/// img : "/9j/4AAQSkZJRgABAgAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAA8AKADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDU8L+GNAuPCejTTaHpkksljA7u9pGWZiikkkjkmtceEfDf/QvaT/4BR/4UnhH/AJE3Q/8AsH2//ota2xQBkDwj4a/6F7Sf/AKP/wCJpw8IeGv+hd0n/wAAo/8A4mtgU4UAZA8IeGf+hd0j/wAAo/8A4mnDwf4Y/wChc0j/AMAY/wD4mtC8vbfTrKa8upRFbwIZJHP8KgZJrN8OeLtH8VRTSaVcNKIGCyBo2QrnOOo74NAEg8HeGP8AoXNI/wDAGL/4mnjwd4X/AOhb0f8A8AYv/ia2BRJKkMbSSOqIoyzMcAD1oAyR4N8L/wDQt6P/AOAMX/xNPHgzwt/0LWj/APgDF/8AE1S0Xx94c1/UpdP0/UVkuY84VlK78d1JHNdSvNAGKPBnhb/oWtH/APAGL/4mnjwX4V/6FrRv/ACL/wCJraFRXV7a2EPnXdxFBFuVN8rhRljgDJ9SQKAMweCvCv8A0LOjf+AEX/xNOHgrwp/0LOjf+AEX/wATW0pBqQUAYg8E+FP+hY0X/wAAIv8A4mnDwR4T/wChY0X/AMAIv/ia3BTxQBhjwR4T/wChX0X/AMF8X/xNOHgfwl/0K+if+C+L/wCJrcFPFAGEPA/hL/oVtE/8F8X/AMTWP4x8G+F7XwP4guLfw3o8M8Wm3DxyR2MSsjCJiCCFyCD3ruBWH44/5J94k/7BV1/6KagDkvCP/ImaF/2D7f8A9FrW2KxfCP8AyJmhf9g+3/8ARa1o6jeppul3d9JjZbQvK2fRQT/SgC4Kd2rwGz+LviaFDdXElldGZWhitBGVZGGMScDkEnGM847da1vCun+IPG1tImpeObi2kR383T4SVnUZ53D5cDJ44IHA46UAdb8TdUgg8KajZtcxJPNCQsbSAM3rgdTxXHfBjUYbS01KOSREJlViWOOMHH8jWrqnwv0DTLV3EdzdTEcy3ExLZ9eMD9K8aGnvDrJ0+WQxnzfLLDvzwfxoA+l/+FjeGE1ePS/7Uia4c7dy8xhvQt0zXGfGLxQf7GXTLG8TMk3l3UaON4GMgEdQD+tcLqPguyj0x5LKW5a5RdwDkEP6jAArnSkuupLdz3jy3yIAVdQS4AwOfpgc0Adn8OZ/D0+saZEtrNBq1vl1mzlZjjkdfTP5V7JqvxA0Tw/qVlpt/O4urrBAVeI1ORuYnoMgjjJrwHwPLeSXqCysLW6ubRvOjDSeVLg8EBuhHOCD/e/K98SLq71WW0urvRrqxuIEMUhfDoVzkYdeOCT+dAHv9n448NX1q08GtWZReu6UKR+B5rgvixr9lrfgCZtMu4rmAXMe94myOD/iRXkmlaRo2pWKmTUGt7vBBQsME/Q1FYSSWM+oaFcP+5uQU56bxyjfjx+YoA9U+HnjrTvC3w0W51GWSQx3DosanLu3BAGT6Y+gr0zwd450nxnYtPp7sksZxLby4Dp6HjqD618y+DUjfxFFa3qiRIi7pBJyvmcAnHrgfpXWeItOu9BvV8T+HGNncRg/aI4hhdvdsenqPxoA+l15qQVwXwz8dr4y0MyTBUv7YiO4RehJHDD2PP5Gu9XmgBwp4pop4oAcKw/HH/JPvEv/AGCrr/0U1borC8c/8k+8S/8AYKuv/RTUAcn4R/5EzQv+wfb/APotal8TaXNrXhnUdNt2jWa4hKIZM7c++CD/AJ6HpUfhD/kTNC/7B9v/AOi1rbFAHnXw9+GMHh0R6nq6pPqvVE+8lv8AT1b37dvU9J4m8Lf2m8WraUyWmv2Z3W1zjh+OY5PVSOPbP1B6QU8UAcjp2sReKNJmEkJttRtm8q8s3+9DJ/VT1B715D4/8OyQyNqECkPF9/H931/D/PSvVfGdrHomtab4whQqsEgtdSKkgPbv8oZvXaxB/wD1Cp/EWirdRsyqGDD6gigDx6x8cp/ZqLe6bM5X5Wnixgn6Hv8AjXNC4gXxJHPZEmKWQfLjH3uor02x8KLpdrNb28LGOQkuHO7NZdj4EhTWUuVjdQrbhH/CDQBzd4tx4T8RWus2i5iL5K9AT/Ep9iOn/wBavVNUgs/EugR3dufNtbmPI9cHt7EfoRUGq+FEv9Pe2njJjkHVeqnsR71reEPC8ei6I9hFNPMjOZP3pBwSBwMDgcfzoA8W022t9E8TNpesQRyWkx2h5FB25+64Pb0P/wBatDxf4Sj0yL7XYRsgjOXUMTx6jPpXoHiPwLbazdw/aRIvlt96PAJHcH2ravfDyvpiQpGTGiBAGJbgDHJPJ/GgD5+/0jy11WGcmaNwJCBhkbseOoPrXbaf4y1bUYfIuItKVhGGHnu0Xmr3I6qffp9K09O8ArYXUzIskiycbH5UDOcY7/jWpfeCbS/s1gntAu1tytGNpUnrjHrQBx/w01bVNI8V3Muk6a18jqVe3jnCjGeMM3Br3eHx7qkKD7Z4F8Qj1Nskc/8AJhXOeDPCsOkFY7aDy1zkk8lj6k16vaoUiAPpQByI+J+lRf8AH7o/iKx9ftOlyDH5ZqWL4teB3fY2upC/92e3ljI/76UV2QoeKOZdssauvowyKAGWN7balZQ3lnOk9tMoeOVDkMPUVleOf+Se+Jf+wVdf+imrcijSKNY40VEUYCqMAD6VieOf+Se+Jf8AsFXX/opqAOT8If8AIl6F/wBg63/9FrW2K+d9N+MXiHS9MtNPgs9MaK1hSFC8UhYqqhRnDjnAq1/wvHxN/wA+Okf9+ZP/AI5QB9AinCvn3/hefib/AJ8dI/78yf8Axyl/4Xp4n/58NI/78y//ABygD3vULCDVNNubC6XdBcxNE49iMfnUWm6SLDR7TT2nkufs8SxebJjcwAwCcV4V/wAL28T/APPhpH/fmX/45S/8L38Uf8+Gj/8AfmX/AOOUAe8HS4T/AAimpo8KvuCCvCv+F8+KP+fDR/8AvzL/APHKX/hfXin/AJ8NG/78y/8AxygD319OidcFRUkFikQ4FfP/APwvzxT/AM+Gjf8AfmX/AOOUv/C/fFQ/5h+jf9+Zf/jlAH0A+nRyNkqKl+wRlNu0V89/8L/8Vf8AQP0b/vzL/wDHKX/hoHxX/wBA/Rf+/Mv/AMcoA9+TR4A2dgqU6TC38A/Kvn3/AIaC8Vj/AJh+i/8AfmX/AOOUv/DQniz/AKB+i/8AfmX/AOOUAfRVtYRwfdUVeUYFfNP/AA0L4t/6B2if9+Zf/jlH/DQ/i3/oHaJ/34l/+OUAfTIp4r5l/wCGiPF3/QO0T/vxL/8AHaX/AIaK8Xf9A7RP+/Ev/wAdoA+nBWF45/5J74l/7BV1/wCimrwH/hovxf8A9A7Q/wDvxL/8dqpq3x78U6xo19pdxYaMsF5byW8jRwyhgrqVJGZCM4PoaAP/2Q=="
/// code : 200
/// uuid : "93387abf7c1948dc91c8652147565222"

Captcha captchaFromJson(String str) => Captcha.fromJson(json.decode(str));

String captchaToJson(Captcha data) => json.encode(data.toJson());

class Captcha {
  Captcha({String? msg, String? img, num? code, String? uuid}) {
    _msg = msg;
    _img = img;
    _code = code;
    _uuid = uuid;
  }

  Captcha.fromJson(dynamic json) {
    _msg = json['msg'];
    _img = json['img'];
    _code = json['code'];
    _uuid = json['uuid'];
  }

  String? _msg;
  String? _img;
  num? _code;
  String? _uuid;

  Captcha copyWith({String? msg, String? img, num? code, String? uuid}) =>
      Captcha(
        msg: msg ?? _msg,
        img: img ?? _img,
        code: code ?? _code,
        uuid: uuid ?? _uuid,
      );

  String? get msg => _msg;

  String? get img => _img;

  num? get code => _code;

  String? get uuid => _uuid;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['msg'] = _msg;
    map['img'] = _img;
    map['code'] = _code;
    map['uuid'] = _uuid;
    return map;
  }

  @override
  String toString() {
    return 'Captcha{_msg: $_msg, _img: $_img, _code: $_code, _uuid: $_uuid}';
  }
}
