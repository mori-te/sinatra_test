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
        inputType: 0,
        inputFileName: "",
        inputData: "",
        outline: "",
        question: "",
        answer: "",
        no: 0
    },
    methods: {
        exec: function () {
            axios.post('/exec_' + vm.lang, {
                user: vm.user,
                lang: vm.lang,
                source: vm.source,
                mode: 1
            }).then(function (response) {
                vm.result = response.data.result;
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
                vm.answer = response.data.answer
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
        change: function () {
            axios.get("/lang?lang=" + this.lang)
            .then(function(response) {
                vm.cmOptions.mode = response.data.lang;
                vm.cmOptions.tabSize = response.data.indent;
                vm.cmOptions.indentUnit = response.data.indent;
                vm.source = response.data.source;
            });
        },
        getUserId: function () {
            axios.get("/userid")
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
        }
    },
    mounted() {
        const no = this.$refs['no'].value;
        if (no > 0) {
            this.edit(no);
        }
        this.change();
        this.getUserId();
    }
})