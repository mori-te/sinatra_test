import {Spinner} from 'https://cdnjs.cloudflare.com/ajax/libs/spin.js/4.1.1/spin.js';
import {compiledMarkdownAndKatex} from './utils.js';

const spinner = new Spinner({color: '#999999'});
const VueCodemirror = window.VueCodemirror;

Vue.use(VueCodemirror);
var vm = new Vue({
    el: "#app",
    data: {
        user: '',
        source: "",
        result: "-",
        lang: 'java',
        cmOptions: {
            tabSize: 4,
            lineNumbers: true,
            indentUnit: 4,
            viewportMargin: 20,
            mode: 'javascript',
            theme: 'lesser-dark'
        },
        task: "",
        level: "D",
        uploadfile: "",
        isEnter: false,
        inputType: "0",
        inputFileName: "",
        inputData: "",
        outline: "",
        question: "",
        answer: "",
        currentTab: "TEXT",
        tabs: ["TEXT", "PREVIEW"],
        isProcessing: false,
        no: 0
    },
    methods: {
        exec: function () {
            vm.isProcessing = true;
            spinner.spin(this.$refs.spin);
            axios.post('/exec_' + vm.lang, {
                user: vm.user,
                lang: vm.lang,
                input_type: vm.inputType,
                input_data: vm.inputData,
                input_file: vm.inputFileName,
                source: vm.source
            }).then(function (response) {
                vm.result = response.data.result;
                spinner.stop();
                vm.isProcessing = false;
            });
        },
        create: function () {
            if (this.isRequired) {
                alert("必須項目は必ず入力してください。");
                return false;
            }
            const no = this.$refs['no'].value;
            axios.post('create_and_edit_question_api', {
                no: no,
                task: vm.task,
                level: vm.level,
                input_type: vm.inputType,
                input_data: vm.inputData,
                input_file_name: vm.inputFileName,
                outline: vm.outline,
                question: vm.question,
                answer: vm.answer,
                user: vm.user,
                source: vm.source
            }).then(function(response) {
                window.location.href = "/menu?level=" + vm.level;
            })
        },
        edit: function (no) {
            axios.get("get_question_api?no=" + no)
            .then(function(response) {
                vm.task = response.data.task;
                vm.level = response.data.level;
                vm.inputType = response.data.input_type;
                vm.inputData = response.data.input_data;
                vm.inputFileName = response.data.input_file_name;
                vm.outline = response.data.outline;
                vm.question = response.data.question;
                vm.answer = response.data.answer;
                vm.getUserId();
            })
        },
        deleteQuestion: function() {
            if (confirm('削除しますか？')) {
                const no = this.$refs['no'].value;
                axios.post('delete_api', {
                    no: no
                }).then(function(response) {
                    window.location.href = "/menu?level=" + vm.level;
                })
            }
        },
        saveQuestion: function() {
            if (confirm('保存しますか？')) {
                const no = this.$refs['no'].value;
                axios.post('save_api', {
                    question_id: no,
                    lang: vm.lang,
                    user_id: vm.user_id,
                    code: vm.source
                }).then(function(response) {
                    alert('保存しました。');
                })
            }
        },
        change: function () {
            const no = this.$refs['no'].value;
            axios.get("/lang", {
                params: {
                    no: no,
                    lang: this.lang
                }
            })
            .then(function(response) {
                vm.cmOptions.mode = response.data.lang;
                vm.cmOptions.tabSize = response.data.indent;
                vm.cmOptions.indentUnit = response.data.indent;
                vm.source = response.data.source;
            });
        },
        back: function () {
            window.location.href = "/menu?level=" + vm.level;
        },
        getUserId: function () {
            axios.get("/userid")
            .then(function(response) {
                vm.user = response.data.userid;
            })
        },
        update: _.debounce(function(e) {
            this.question = e.target.value;
        }, 300)
    },
    computed: {
        isRequired() {
            if (this.outline == "" || this.question == "" || this.answer == "") {
                return true;
            }
            return false;
        },
        isInputFile() {
            return (this.inputType != 2);
        },
        isInputData() {
            return (this.inputType == 0);
        },
        compiledMarkdown() {
            return compiledMarkdownAndKatex({
                question: this.question
            });
        },
        isShowText() {
            return this.currentTab == this.tabs[0];
        },
        isShowPreview() {
            return this.currentTab == this.tabs[1];
        }
    },
    async mounted() {
        const no = this.$refs['no'].value;
        if (no > 0) {
            await this.edit(no);
        }
        await this.change();
    }
})