export interface SystemAlarms {
  [key: string]: Alarm[];
}

export interface Alarm {
  name: string;
  last_raised: number;
  value: string;
}
