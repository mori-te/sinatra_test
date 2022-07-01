INSERT INTO questions (
    task, level, input_type, parameter, file_name, file_data, outline, question, answer, cr_user, cr_date, up_user, up_date, del_flag
) values (
    '1-1', 'D', 0, null, null, null, 'Hello Worldの表示', 'Hello Worldを表示するプログラムを作成しなさい。文字列の最後に改行コードを付けて下さい。', 'Hello World', 'mori-te', now(), 'mori-te', now(), '0'
);

INSERT INTO teachers (
    id, lang_id, userid, del_flag
) values (
    1, 1, 'yoshida-sa', '0'
), (
    2, 2, 'mori-te', '0'
), (
    3, 3, 'yoshida-sa', '0'
), (
    4, 4, 'nakamura-ma', '0'
), (
    5, 5, 'nakamura-ma', '0'
), (
    6, 6, 'nose-ju', '0'
), (
    7, 7, 'nose-ju', '0'
), (
    8, 8, 'satou-ko', '0'
);

INSERT INTO languages (
    id, shot_name, name, del_flag
) values (
    1, 'java', 'Java', '0'
), (
    2, 'ruby', 'Ruby', '0'
), (
    3, 'js', 'javascript(node)', '0'
), (
    4, 'python', 'Python', '0'
), (
    5, 'golang', 'Go', '0'
), (
    6, 'cobol', 'COBOL', '0'
), (
    7, 'casl2', 'CASLⅡ', '0'
), (
    8, 'clang', 'C言語', '0'
);