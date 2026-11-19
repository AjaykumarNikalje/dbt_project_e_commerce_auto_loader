{% macro is_backfill() %}
    {% set mode = var('load_mode', 'incremental') %}
    {% if mode not in ['incremental', 'backfill'] %}
        {{ exceptions.raise_compiler_error('load_mode must be incremental or backfill.') }}
    {% endif %}

    {% if mode == 'backfill' %}
        {% if flags.FULL_REFRESH %}
            {{ exceptions.raise_compiler_error('Backfill uses MERGE; do not use --full-refresh.') }}
        {% endif %}
        {% for name in ['from_date', 'to_date'] %}
            {% set value = var(name, none) %}
            {% if value is none or not modules.re.fullmatch('[0-9]{4}-[0-9]{2}-[0-9]{2}', value | string) %}
                {{ exceptions.raise_compiler_error('Backfill requires ' ~ name ~ ' in YYYY-MM-DD format.') }}
            {% endif %}
            {% do modules.datetime.datetime.strptime(value | string, '%Y-%m-%d') %}
        {% endfor %}
        {% if var('from_date') | string > var('to_date') | string %}
            {{ exceptions.raise_compiler_error('from_date must be on or before to_date.') }}
        {% endif %}
    {% endif %}

    {{ return(mode == 'backfill') }}
{% endmacro %}
