TRUNCATE TABLE `questions`;
INSERT INTO `questions` VALUES (1,'1-1','D','0',NULL,NULL,NULL,'Hello Worldの表示','Hello Worldを表示するプログラムを作成しなさい。文字列の最後に改行コードを付けて下さい。','Hello World','mori-te','2022-07-14 05:44:14','mori-te','2022-07-14 05:44:14','0'),(2,'1-2','D','1','1234567890',NULL,NULL,'入力値の表示','入力値を左右反転して表示させなさい。','0987654321','mori-te','2022-07-14 05:44:14','mori-te','2022-07-14 05:44:14','0'),(3,'1-3','D','2',NULL,'test.txt','あいうえお\nかきくけこ\nさしすせそ\n','行番号付き出力','ファイルからデ ータを読み込んで行番号を付けて表示しなさい','01: あいうえお\n02: かきくけこ\n03: さしすせそ\n','mori-te','2022-07-14 05:44:14','mori-te','2022-07-14 05:44:14','0'),(4,'1-4','D','1','PINEAPPLE',NULL,NULL,'文字列を囲む','標準入力で受け取った1行の文字列（可変）を＊で隙間なく囲みなさい。\n以下例。\n```\n*******  ********\n*APPLE*  *ORANGE*\n*******  ********\n```\n','***********\n*PINEAPPLE*\n***********','mori-te','2022-07-15 00:51:16','mori-te','2022-07-15 00:51:16','0'),(5,'2-1','C','0',NULL,NULL,NULL,'ピタゴラスの定理','ピタゴラス の定理 $$a^2 + b^2 = c^2$$ が成立する　1～100 の整数の組み合わせ(a,b,c)は何通りか？','52','mori-te','2022-07-15 05:41:20','mori-te','2022-07-15 05:41:20','0'),(6,'1-5','D','1','5,3,6,1,2,9,8,4,7',NULL,NULL,'簡単なソート問題','標準入力で与えられたカンマ区切りの数値を左から降順で並び替えなさい。','9,8,7,6,5,4,3,2,1','mori-te','2022-07-25 04:28:29','mori-te','2022-07-25 04:28:29','0'),(7,'1-6','D','1','5,3,10,6,1,2,9,8,4,7',NULL,NULL,'簡単なソート問題（その２）','標準入力で与えられたカンマ区切りの数値を左から降順で並び替えなさい。','10,9,8,7,6,5,4,3,2,1','mori-te','2022-07-25 04:32:38','mori-te','2022-07-25 04:32:38','0'),(8,'1-7','D','1','1-2,2-3,1-1,2-10,1-3',NULL,NULL,'簡単なソート問題（その３）','ファイル で与えられたカンマ区切りの\"数値1-数値2\"を並び替えなさい。  \nただし、数値1を第1ソートキー（昇順）、数値2を第2ソートキー（降順）とする。','1-3,1-2,1-1,2-10,2-3','mori-te','2022-07-25 05:05:08','mori-te','2022-07-25 05:05:08','0'),(9,'1-8','D','1','12345678901',NULL,NULL,'カンマ付き数値の表示','標準入力から受け取った値に右から三桁ずつ,を挿入させてください 。','12,345,678,901','mori-te','2022-08-02 07:27:22','mori-te','2022-08-02 07:27:22','0'),(10,'1-9','D','1','11',NULL,NULL,'棒グラフ','標準入力から数値を受け取り、その個数だけ*を 、5個おきに空白（スペース）を入れて表示するプログラムを作成せよ。入力値が0以下の値の場合は何も書かなくてよい。','***** ***** *','mori-te','2022-08-02 07:28:04','mori-te','2022-08-02 07:28:04','0'),(11,'1-10','D','1','ABCDEI',NULL,NULL,'変換処理','標準入力からAからIまでの英字が複数文字入力されるので、A ? 1, B ? 2, C ? 3 と英字を数値に以下のように変換するプ ログラムを作成しなさい。\n\nACDI ? 1349','123459','mori-te','2022-08-02 07:44:57','mori-te','2022-08-02 07:44:57','0'),(13,'1-11','D','1','2 5',NULL,NULL,'四角形の表示','標準入力 から「数値（縦）＋スペース＋数値（横）」の値を取得し、数値（縦）× 数値（横）の*で埋めた四角形を表示しなさい。','*****\n*****\n','mori-te','2022-08-02 08:19:14','mori-te','2022-08-02 08:19:14','0'),(14,'1-12','D','0',NULL,NULL,NULL,'素数を求める','1から100まで数値から素数（2 以上の自然数で、正の約数が 1 と自分自身のみであるもの）を求め、カンマ区切りで表示 せよ。','2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97','mori-te','2022-08-02 08:41:19','mori-te','2022-08-02 08:41:19','0');
