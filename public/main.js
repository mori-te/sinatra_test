import {Spinner} from 'https://cdnjs.cloudflare.com/ajax/libs/spin.js/4.1.1/spin.js';

const spinner = new Spinner({color: '#999999'});
const VueCodemirror = window.VueCodemirror;
Vue.use(VueCodemirror);
// メイン処理
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
        uploadfile: "",
        isEnter: false,
        isProcessing: false
    },
    methods: {
        exec: function () {
            vm.isProcessing = true;
            spinner.spin(this.$refs.spin);
            axios.post('exec_' + vm.lang, {
                user: vm.user,
                lang: vm.lang,
                source: vm.source
            }).then(function (response) {
                vm.result = response.data.result;
                spinner.stop();
                vm.isProcessing = false;
            });
        },
        submitted: function () {
            if (confirm('提出しますか？')) {
                vm.task = this.$refs['task'].textContent;
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
            const level = this.$refs['level'].value;
            window.location.href = "/menu?level=" + level;
        },
        getUserId: function () {
            axios.get("userid")
            .then(function(response) {
                vm.user = response.data.userid;
            })
        },
        dragEnter: function () {
            this.isEnter = true;
        },
        dragLeave: function () {
            this.isEnter = false;
        },
        dragOver: function () {
            console.log("dragover");
        },
        dropFile: function (e) {
            const file = e.dataTransfer.files[0]
            let form = new FormData();
            form.append('file', file);
            form.append('user', vm.user);
            axios.post("upload", form)
            .then(function(response) {
                console.log(response.data);
            });
            vm.uploadfile = `[${file["name"]}]`
            this.isEnter = false;
        }
    },
    mounted() {
        this.change();
        this.getUserId();
    }
})