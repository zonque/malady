Malady shall be a tool to track health parameter metrics such as temperature, weight, medication, female period, heart rate etc. The categories to track shall be configurable for each person.

Multi-user. Users can sign up and then get access to their personal dashboard.

Each data point column shall be configurable (number, percentage, boolean, enumeration, ...), and they can also be changed after data has been entered.

tech stack: ruby on rails with hotwire. use haml. prepare for i18n but stick to english for now. postgresql. mobile first, slick design. optional dark mode.

add extensive tests for models and controllers.

data export shall be possible as JSON and CSV. visualization through Grafana if possible. think about the adapters needed for that.

privacy first: data must be secure.

whether signups are allowed depends on an environment variable.
