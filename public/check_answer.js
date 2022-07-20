import {Spinner} from 'https://cdnjs.cloudflare.com/ajax/libs/spin.js/4.1.1/spin.js';

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
        inputName: "",
        inputFileName: "",
        inputData: "",
        outline: "",
        question: "",
        answer: "",
        createUser: "",
        userid: "",
        no: 0,
        isProcessing: false,
        isReadonly: true
    },
    methods: {
        check_answer: function (pid) {
            axios.get("check_progress_api?pid=" + pid)
            .then(function(response) {
                vm.no = response.data.question.id;
                vm.task = response.data.question.task;
                vm.level = response.data.question.level;
                vm.outline = response.data.question.outline;
                vm.question = response.data.question.question;
                vm.source = response.data.question.code;
                vm.lang = response.data.question.shot_name;
                vm.inputType = response.data.input_type;
                vm.inputName = response.data.input_name;
                vm.inputData = response.data.input_data;
                vm.inputFileName = response.data.question.file_name;
                vm.result = response.data.question.result;
                vm.answer = response.data.question.answer;
                vm.userid = response.data.question.userid;
                vm.createUser = response.data.question.cr_user;
                vm.isReadonly = response.data.input_readonly;
            })
        },
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
        back: function () {
            window.location.href = "/admin/check";
        },
        getUserId: function () {
            axios.get("/userid")
            .then(function(response) {
                vm.user = response.data.userid;
            })
        },
        clickOK: function (e) {
            axios.post("set_status_api", {
                id: e.target.value,
                status: 0
            })
            .then(function(response) {
                alert("OKに設定しました。");
            })
        },
        clickNG: function (e) {
            axios.post("set_status_api", {
                id: e.target.value,
                status: 1
            })
            .then(function(response) {
                alert("NGに設定しました。");
            })
        },
        resetParameter: function () {
            axios.get("get_question_api?no=" + vm.no)
            .then(function(response) {
                vm.inputData = response.data.input_data;
                vm.result = '';
            })
        }
    },
    computed: {
        compiledMarkdown() {
            const placeholder = "[katex][/katex]";
            const re = /\$\$ *([^\$\n]*) *\$\$/g;
            var expressions = [];
            var matches;
            var text = this.question;
            while ((matches = re.exec(text)) != null) {
                expressions.push(matches);
            }
            for (const expression of expressions) {
                text = text.replace(expression[0], placeholder);
            }
            var markdown = marked(text, { sanitize: true });
            for (const expression of expressions) {
                markdown = markdown.replace(placeholder, katex.renderToString(expression[1]));
            }
            return markdown;
        }
    },
    mounted() {
        const pid = this.$refs['pid'].value;
        this.check_answer(pid);
        this.getUserId();
    }
})