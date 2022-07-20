import {Spinner} from 'https://cdnjs.cloudflare.com/ajax/libs/spin.js/4.1.1/spin.js';
import {compiledMarkdownAndKatex} from './utils.js'

const spinner = new Spinner({color: '#999999'});
const VueCodemirror = window.VueCodemirror;
Vue.use(VueCodemirror);
// メイン処理
var vm = new Vue({
    el: "#app",
    data: {
        user: '',
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
        outline: "",
        question: "",
        source: "",
        inputType: "0",
        inputName: "",
        inputData: "",
        inputFileName: "",
        result: "-",
        answer: "",
        isEnter: false,
        isProcessing: false,
        isReadonly: true
    },
    methods: {
        exec: function () {
            vm.isProcessing = true;
            spinner.spin(this.$refs.spin);
            axios.post('exec_' + vm.lang, {
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
        submitted: function () {
            if (confirm('提出しますか？')) {
                axios.post('submit_code', {
                    user: vm.user,
                    lang: vm.lang,
                    task: vm.task,
                    result: vm.result,
                    source: vm.source
                }).then(function(response) {
                    alert('提出しました。');
                })
            }
        },
        change: function () {
            axios.get("lang?lang=" + this.lang)
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
            axios.get("userid")
            .then(function(response) {
                vm.user = response.data.userid;
            })
        },
        getQuestion: function () {
            const no = this.$refs['no'].value;
            axios.get("get_question_api?no=" + no)
                .then(function (response) {
                    vm.task = response.data.question.task;
                    vm.level = response.data.question.level;
                    vm.outline = response.data.question.outline;
                    vm.question = response.data.question.question;
                    vm.source = response.data.question.code || vm.source;
                    vm.lang = response.data.question.shot_name || vm.lang;
                    vm.inputType = response.data.input_type;
                    vm.inputName = response.data.input_name;
                    vm.inputData = response.data.input_data;
                    vm.inputFileName = response.data.question.file_name;
                    vm.result = response.data.question.result;
                    vm.answer = response.data.question.answer;
                    vm.isReadonly = response.data.input_readonly;

                    if (vm.source == "") {
                        vm.lang = 'java';
                        vm.change();
                    }
                }).catch(function (response) {
                    return false;
                });
            return true;
        },
        resetParameter: function () {
            const no = this.$refs['no'].value;
            axios.get("get_question_api?no=" + no)
            .then(function(response) {
                vm.inputData = response.data.input_data;
                vm.result = '';
            })
        }
    },
    computed: {
        compiledMarkdown() {
            return compiledMarkdownAndKatex({
                question: this.question
            });
        }
    },
    mounted() {
        this.getQuestion();
        this.getUserId();
    }
})