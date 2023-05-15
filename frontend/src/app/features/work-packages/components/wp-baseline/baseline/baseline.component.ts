// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  HostBinding,
  Input,
  OnInit,
  Output,
} from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import SpotDropAlignmentOption from 'core-app/spot/drop-alignment-options';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { IDay } from 'core-app/core/state/days/day.model';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { Observable } from 'rxjs';
import {
  DEFAULT_TIMESTAMP,
  WorkPackageViewBaselineService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { validDate } from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';
import { baselineFilterFromValue } from 'core-app/features/work-packages/components/wp-baseline/baseline-helpers';
import * as moment from 'moment-timezone';

@Component({
  selector: 'op-baseline',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './baseline.component.html',
  styleUrls: ['./baseline.component.sass'],
})
export class OpBaselineComponent extends UntilDestroyedMixin implements OnInit {
  @HostBinding('class.op-baseline') className = true;

  @Output() submitted = new EventEmitter<void>();

  @Input() showActionBar? = false;

  @Input() visible = true;

  public mappedSelectedDate:string|null;

  public nonWorkingDays$:Observable<IDay[]> = this.wpTableBaseline.nonWorkingDays$;

  public selectedDates:string[];

  public selectedTimes:string[];

  public selectedFilter:string|null;

  public selectedTimezoneFormattedTime:string[];

  public tooltipPosition = SpotDropAlignmentOption.TopRight;

  public text = {
    toggle_title: this.I18n.t('js.baseline.toggle_title'),
    drop_down_none_option: this.I18n.t('js.baseline.drop_down.none'),
    header_description: this.I18n.t('js.baseline.header_description'),
    clear: this.I18n.t('js.baseline.clear'),
    apply: this.I18n.t('js.baseline.apply'),
    show_changes_since: this.I18n.t('js.baseline.show_changes_since'),
    from: this.I18n.t('js.baseline.from'),
    to: this.I18n.t('js.baseline.to'),
    date: this.I18n.t('js.label_date'),
    time: this.I18n.t('js.baseline.time'),
    help_description: this.I18n.t('js.baseline.help_description'),
    timeZone: this.configuration.isDefaultTimezoneSet() ? moment().tz(this.configuration.defaultTimezone()).zoneAbbr() : 'local',
    time_description: (i:number) => {
      const date = this.selectedDates[i];
      const time = this.selectedTimes[i];

      if (!date || !time) {
        return '';
      }

      const formatted = moment
        .tz(`${date}T${time}`, this.configuration.defaultTimezone())
        .tz(this.configuration.timezone());

      const formattedDate = formatted.format(this.timezoneService.getDateFormat());
      const formattedTime = formatted.format(this.timezoneService.getTimeFormat());
      return this.I18n.t('js.baseline.time_description', {
        datetime: `${formattedDate} ${formattedTime}`,
      });
    },
  };

  public baselineAvailableValues = [
    {
      value: 'oneDayAgo',
      title: this.I18n.t('js.baseline.drop_down.yesterday'),
    },
    {
      value: 'lastWorkingDay',
      title: this.I18n.t('js.baseline.drop_down.last_working_day'),
    },
    {
      value: 'oneWeekAgo',
      title: this.I18n.t('js.baseline.drop_down.last_week'),
    },
    {
      value: 'oneMonthAgo',
      title: this.I18n.t('js.baseline.drop_down.last_month'),
    },
    {
      value: 'aSpecificDate',
      title: this.I18n.t('js.baseline.drop_down.a_specific_date'),
    },
    {
      value: 'betweenTwoSpecificDates',
      title: this.I18n.t('js.baseline.drop_down.between_two_specific_dates'),
    },
  ];

  constructor(
    readonly I18n:I18nService,
    readonly wpTableBaseline:WorkPackageViewBaselineService,
    readonly halResourceService:HalResourceService,
    readonly weekdaysService:WeekdayService,
    readonly daysService:DayResourceService,
    readonly timezoneService:TimezoneService,
    readonly configuration:ConfigurationService,
  ) {
    super();
  }

  public ngOnInit():void {
    this.resetSelection();

    if (this.wpTableBaseline.isActive()) {
      this.filterChange(baselineFilterFromValue(this.wpTableBaseline.current));

      this.wpTableBaseline.current.forEach((value, i) => {

        if (value.includes('@')) {
          const [, timeWithZone] = value.split(/[@]/);
          const time = timeWithZone.split(/[+-]/)[0];
          this.selectedTimes[i] = time || '00:00';
        } else if (value !== 'PT0S') {
          const date = moment.tz(value, this.configuration.defaultTimezone());

          this.selectedDates[i] = date.format('YYYY-MM-DD');
          this.selectedTimes[i] = date.format('HH:mm');
        }
      });
    }
  }

  public resetSelection():void {
    this.selectedTimes = ['00:00', '00:00'];
    this.selectedDates = ['', ''];
    this.selectedFilter = null;
    this.mappedSelectedDate = null;
  }

  public onSubmit(e:Event):void {
    e.preventDefault();
    this.onSave();
  }

  public onSave() {
    this.wpTableBaseline.update(this.buildBaselineFilter());
    this.submitted.emit();
  }

  public timesChange(value:string[]):void {
    this.selectedTimes = value;
  }

  public dateChange(values:string[]):void {
    if (_.every(values, validDate)) {
      this.selectedDates = values;
    }
  }

  public filterChange(value:string|null):void {
    this.selectedFilter = value;
    switch (value) {
      case 'oneDayAgo':
        this.mappedSelectedDate = this.timezoneService.formattedDate(this.wpTableBaseline.yesterdayDate());
        break;
      case 'lastWorkingDay':
        this.mappedSelectedDate = this.timezoneService.formattedDate(this.wpTableBaseline.lastWorkingDate());
        break;
      case 'oneWeekAgo':
        this.mappedSelectedDate = this.timezoneService.formattedDate(this.wpTableBaseline.lastweekDate());
        break;
      case 'oneMonthAgo':
        this.mappedSelectedDate = this.timezoneService.formattedDate(this.wpTableBaseline.lastMonthDate());
        break;
      default:
        this.mappedSelectedDate = null;
        break;
    }
  }

  private buildBaselineFilter():string[] {
    switch (this.selectedFilter) {
      case 'oneDayAgo':
      case 'oneWeekAgo':
      case 'oneMonthAgo':
      case 'lastWorkingDay':
        return [this.buildISOString(0), DEFAULT_TIMESTAMP];
      case 'aSpecificDate':
        return [this.buildISOString(0), DEFAULT_TIMESTAMP];
      case 'betweenTwoSpecificDates':
        return [
          this.buildISOString(0),
          this.buildISOString(1),
        ];
      default:
        return [DEFAULT_TIMESTAMP];
    }
  }

  private buildISOString(i:number):string {
    const date = moment.tz(`${this.selectedDates[i]}T${this.selectedTimes[i]}`, this.configuration.defaultTimezone());
    return date.toISOString();
  }
}
