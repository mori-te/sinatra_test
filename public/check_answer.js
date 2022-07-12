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
        inputName: "",
        inputFileName: "",
        inputData: "",
        outline: "",
        question: "",
        answer: "",
        no: 0,
        isProcessing: false
    },
    methods: {
        check_answer: function (pid) {
            axios.get("check_progress_api?pid=" + pid)
            .then(function(response) {
                vm.task = response.data.question.task;
                vm.level = response.data.question.level;
                vm.outline = response.data.question.outline;
                vm.question = response.data.question.question;
                vm.source = response.data.question.code;
                vm.lang = response.data.question.shot_name;
                vm.inputName = response.data.input_type;
                vm.inputData = response.data.input_data;
                vm.inputFileName = response.data.question.input_file_name;
                vm.result = response.data.question.result;
                vm.answer = response.data.question.answer;
                vm.userid = response.data.question.userid;
                vm.createUser = response.data.question.cr_user;
            })
        },
        exec: function () {
            vm.isProcessing = true;
            spinner.spin(this.$refs.spin);
            axios.post('/exec_' + vm.lang, {
                user: vm.user,
                lang: vm.lang,
                source: vm.source,
                mode: 1
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
        }
    },
    mounted() {
        const pid = this.$refs['pid'].value;
        this.check_answer(pid);
        this.getUserId();
    }
})