var vm = new Vue({
    el: "#app",
    data: {
        user: "",
        list: [],
        users: []
    },
    methods: {
        getSubmmitedList: function () {
            axios.get("submmited_list_api?user=" + this.user)
            .then(function(response) {
                vm.list = response.data.list;
                vm.user = response.data.user;
            })
        },
        getSubmmitedUsers: function () {
            axios.get("get_submmited_users_api")
            .then(function(response) {
                vm.users = response.data.list;
                if (vm.users.length > 0) {
                    vm.user = response.data.list[0].userid;
                    vm.getSubmmitedList();
                }
            })
        },
        clickOK: function (e) {
            axios.post("set_status_api", {
                id: e.target.value,
                status: 0
            })
            .then(function(response) {
                vm.getSubmmitedList();
            })
        },
        clickNG: function (e) {
            axios.post("set_status_api", {
                id: e.target.value,
                status: 1
            })
            .then(function(response) {
                vm.getSubmmitedList();
            })
        }
    },
    mounted() {
        this.getSubmmitedUsers();
        //this.getSubmmitedList();
    }
})